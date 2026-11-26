import Foundation

public enum MessengerError: Error, Equatable {
    case invalidOrExpiredQR
    case ownKey
    case dailyLimitReached
    case unknownContact
    case notAccepted
    case blocked
    case emptyText
    case textTooLong
    case cryptoFailure
}

public enum AddContactOutcome: Equatable {

    case requestSent(contactId: String)

    case keyChangeAlert(contactId: String)
}

public protocol MessengerDelegate: AnyObject {
    func messenger(_ m: MeshMessenger, didReceive message: ChatMessage)
    func messenger(_ m: MeshMessenger, didUpdate message: ChatMessage)
    func messenger(_ m: MeshMessenger, contactRequestFrom contact: Contact)
    func messenger(_ m: MeshMessenger, didUpdate contact: Contact)
    func messenger(_ m: MeshMessenger, keyChangedFor contact: Contact)
}

public final class MeshMessenger: MeshNodeDelegate {
    public static let maxTextBytes = 4000
    private static let textKind: UInt8 = 0x01
    private static let payloadKind: UInt8 = 0x02

    private struct HandshakeState: Codable {
        struct Challenge: Codable { var contactId: String; var verifyOnSuccess: Bool; var createdMs: Int64 }
        var challenges: [String: Challenge] = [:]

        var pendingRequests: [String: String] = [:]
    }

    public let crypto: IdentityCrypto
    public let sessions: SessionCrypto
    public let node: MeshNode
    public let contacts: ContactBook
    public let abuse: AbuseGuard
    public let messages: MessageLog
    public var displayName: String
    public weak var delegate: MessengerDelegate?
    public var payloadHandler: ((Data, Contact) -> Void)?

    private let store: DocumentStore
    private let nowMs: NowMs
    private var handshake: HandshakeState

    public init(crypto: IdentityCrypto, sessions: SessionCrypto, node: MeshNode, contacts: ContactBook,
                abuse: AbuseGuard, messages: MessageLog, store: DocumentStore, displayName: String,
                now: @escaping NowMs = systemNowMs) {
        self.crypto = crypto
        self.sessions = sessions
        self.node = node
        self.contacts = contacts
        self.abuse = abuse
        self.messages = messages
        self.store = store
        self.displayName = displayName
        self.nowMs = now
        self.handshake = Documents.read(HandshakeState.self, from: store, name: "handshake") ?? HandshakeState()
        node.delegate = self
        node.isForMe = { [weak self] env in self?.matchTag(env) != nil }
    }

    private func persistHandshake() { Documents.write(handshake, to: store, name: "handshake") }

    private enum TagMatch {
        case inbox
        case direct(Contact)
    }

    private func routingSecret(for contact: Contact) -> Data? {
        if let s = contact.routingSecret { return s }
        guard let shared = crypto.sharedSecret(with: contact.identityKey) else { return nil }
        return RoutingTags.routingSecret(fromSharedSecret: shared)
    }

    private func matchTag(_ env: Envelope) -> TagMatch? {
        let t = nowMs()
        let epochs = RoutingTags.acceptedEpochs(nowMs: t)
        switch env.kind {
        case .inbox:
            for e in epochs where RoutingTags.inboxTag(identityPublic: crypto.publicKey, epoch: e) == env.tag {
                return .inbox
            }
        case .direct:
            for c in contacts.all() where c.status == .accepted {
                guard let secret = routingSecret(for: c) else { continue }
                for e in epochs where RoutingTags.directTag(routingSecret: secret, recipientPublic: crypto.publicKey, epoch: e) == env.tag {
                    return .direct(c)
                }
            }
        }
        return nil
    }

    private func directEnvelope(to c: Contact, bodyType: BodyType, body: Data) -> Envelope? {
        guard let secret = routingSecret(for: c) else { return nil }
        let tag = RoutingTags.directTag(routingSecret: secret, recipientPublic: c.identityKey,
                                        epoch: RoutingTags.epoch(atMs: nowMs()))
        return Envelope(kind: .direct, bodyType: bodyType, ttl: 0, tag: tag, body: body)
    }

    private func inboxEnvelope(toKey key: Data, bodyType: BodyType, body: Data) -> Envelope {
        let tag = RoutingTags.inboxTag(identityPublic: key, epoch: RoutingTags.epoch(atMs: nowMs()))
        return Envelope(kind: .inbox, bodyType: bodyType, ttl: 0, tag: tag, body: body)
    }

    public func myQR() -> String {
        return ContactQR.make(crypto: crypto, displayName: displayName, nowMs: nowMs()).encode()
    }

    @discardableResult
    public func addContact(fromQR text: String, firstText: String = "") throws -> AddContactOutcome {
        guard let qr = ContactQR.decode(text), qr.verify(crypto: crypto, nowMs: nowMs()) else {
            throw MessengerError.invalidOrExpiredQR
        }
        if qr.identityKey == crypto.publicKey { throw MessengerError.ownKey }
        switch contacts.evaluate(key: qr.identityKey, displayName: qr.displayName) {
        case .known(let id):
            guard let c = contacts.contact(id: id) else { throw MessengerError.unknownContact }
            if c.blocked { throw MessengerError.blocked }

            try sendRequest(to: c, verifyOnSuccess: true, firstText: firstText)
            return .requestSent(contactId: id)
        case .keyChanged(let id):
            contacts.raiseKeyChange(id: id, newKey: qr.identityKey, nowMs: nowMs())
            if let c = contacts.contact(id: id) { delegate?.messenger(self, keyChangedFor: c) }
            return .keyChangeAlert(contactId: id)
        case .newIdentity:
            guard abuse.canContactNewStranger(nowMs: nowMs()) else { throw MessengerError.dailyLimitReached }
            abuse.recordOutgoingStranger(nowMs: nowMs())
            let secret = crypto.sharedSecret(with: qr.identityKey).map { RoutingTags.routingSecret(fromSharedSecret: $0) }
            let c = contacts.add(key: qr.identityKey, displayName: qr.displayName, status: .pendingOutgoing,
                                 nowMs: nowMs(), routingSecret: secret)
            try sendRequest(to: c, verifyOnSuccess: true, firstText: firstText)
            return .requestSent(contactId: c.id)
        }
    }

    private func sendRequest(to c: Contact, verifyOnSuccess: Bool, firstText: String) throws {
        var nonceBytes = [UInt8]()
        for _ in 0..<Handshake.nonceSize { nonceBytes.append(UInt8.random(in: 0...255)) }
        let nonce = Data(nonceBytes)
        let body = Handshake.makeRequest(crypto: crypto, targetKey: c.identityKey, name: displayName,
                                         firstText: firstText, nonce: nonce)
        handshake.challenges[nonce.toHex()] = HandshakeState.Challenge(
            contactId: c.id, verifyOnSuccess: verifyOnSuccess, createdMs: nowMs())
        persistHandshake()
        node.enqueue(inboxEnvelope(toKey: c.identityKey, bodyType: .bundleRequest, body: body))
    }

    public func acceptRequest(contactId: String) throws {
        guard let c = contacts.contact(id: contactId) else { throw MessengerError.unknownContact }
        if c.blocked { throw MessengerError.blocked }
        guard let nonceHex = handshake.pendingRequests[contactId], let nonce = Data(meshHex: nonceHex) else {
            throw MessengerError.notAccepted
        }
        try respond(to: c, nonce: nonce)
        handshake.pendingRequests[contactId] = nil
        persistHandshake()
        if let text = c.requestText, !text.isEmpty {
            let m = ChatMessage(id: UUID().uuidString, contactId: c.id, outgoing: false, text: text,
                                timestampMs: nowMs(), state: .received, outboxId: nil)
            messages.add(m)
            delegate?.messenger(self, didReceive: m)
        }
    }

    public func rejectRequest(contactId: String, block: Bool) {
        guard let c = contacts.contact(id: contactId) else { return }
        if block { abuse.block(key: c.identityKey) }
        contacts.remove(id: contactId)
        handshake.pendingRequests[contactId] = nil
        persistHandshake()
    }

    private func respond(to c: Contact, nonce: Data) throws {
        guard let bundle = try? sessions.makeBundle() else { throw MessengerError.cryptoFailure }
        let secret = crypto.sharedSecret(with: c.identityKey).map { RoutingTags.routingSecret(fromSharedSecret: $0) }
        contacts.setStatus(id: c.id, .accepted)
        if let secret = secret { contacts.setRoutingSecret(id: c.id, secret) }
        let body = Handshake.makeResponse(crypto: crypto, nonce: nonce, requesterKey: c.identityKey, bundle: bundle)
        node.enqueue(inboxEnvelope(toKey: c.identityKey, bodyType: .bundle, body: body))
        if let fresh = contacts.contact(id: c.id) { delegate?.messenger(self, didUpdate: fresh) }
    }

    private func handleRequest(_ env: Envelope) {
        guard let req = Handshake.parseRequest(env.body, crypto: crypto) else { return }
        if req.requesterKey == crypto.publicKey { return }
        switch contacts.evaluate(key: req.requesterKey, displayName: req.requesterName) {
        case .known(let id):
            guard let c = contacts.contact(id: id), !c.blocked else { return }
            switch c.status {
            case .accepted, .pendingOutgoing:

                try? respond(to: c, nonce: req.nonce)
            case .pendingIncoming:
                handshake.pendingRequests[id] = req.nonce.toHex()
                persistHandshake()
            }
        case .keyChanged(let id):
            contacts.raiseKeyChange(id: id, newKey: req.requesterKey, nowMs: nowMs())
            if let c = contacts.contact(id: id) { delegate?.messenger(self, keyChangedFor: c) }
        case .newIdentity:
            guard abuse.evaluateRequest(senderKey: req.requesterKey, text: req.firstText, nowMs: nowMs()) == .accept else { return }
            abuse.recordRequest(senderKey: req.requesterKey, nowMs: nowMs())
            let c = contacts.add(key: req.requesterKey, displayName: req.requesterName, status: .pendingIncoming,
                                 nowMs: nowMs(), routingSecret: nil, requestText: req.firstText)
            handshake.pendingRequests[c.id] = req.nonce.toHex()
            persistHandshake()
            delegate?.messenger(self, contactRequestFrom: c)
        }
    }

    private func handleBundle(_ env: Envelope) {
        guard let nonce = Handshake.peekNonce(env.body),
              let ch = handshake.challenges[nonce.toHex()],
              let c = contacts.contact(id: ch.contactId),
              let resp = Handshake.parseResponse(env.body, crypto: crypto, targetKey: c.identityKey, expectedNonce: nonce)
        else { return }
        do {
            try sessions.startSession(contactId: c.id, remoteIdentity: c.identityKey, bundle: resp.bundle)
        } catch {
            return
        }
        handshake.challenges[nonce.toHex()] = nil
        persistHandshake()
        contacts.setStatus(id: c.id, .accepted)
        if ch.verifyOnSuccess { contacts.markVerified(id: c.id, nowMs: nowMs()) }
        if let fresh = contacts.contact(id: c.id) { delegate?.messenger(self, didUpdate: fresh) }
        flushWaiting(for: c.id)
    }

    public func resolveKeyChange(contactId: String, accept: Bool) {
        guard let c = contacts.contact(id: contactId), let newKey = c.keyChangeCandidate else { return }
        if accept {
            let secret = crypto.sharedSecret(with: newKey).map { RoutingTags.routingSecret(fromSharedSecret: $0) }
            contacts.acceptKeyChange(id: contactId, routingSecret: secret)
            sessions.resetAllSessions()
        } else {
            contacts.dismissKeyChange(id: contactId)
        }
        if let fresh = contacts.contact(id: contactId) { delegate?.messenger(self, didUpdate: fresh) }
    }

    @discardableResult
    public func sendText(to contactId: String, text: String) throws -> ChatMessage {
        guard let c = contacts.contact(id: contactId) else { throw MessengerError.unknownContact }
        if c.blocked { throw MessengerError.blocked }
        guard c.status == .accepted else { throw MessengerError.notAccepted }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw MessengerError.emptyText }
        if trimmed.utf8.count > MeshMessenger.maxTextBytes { throw MessengerError.textTooLong }
        var m = ChatMessage(id: UUID().uuidString, contactId: c.id, outgoing: true, text: trimmed,
                            timestampMs: nowMs(), state: .waitingSession, outboxId: nil)
        messages.add(m)
        if sessions.hasSession(contactId: c.id) {
            transmit(&m, to: c)
        } else {

            try? sendRequest(to: c, verifyOnSuccess: c.trust == .verified, firstText: "")
        }
        return m
    }

    @discardableResult
    public func sendPayload(_ payload: Data, to contactId: String) throws -> String {
        guard let c = contacts.contact(id: contactId) else { throw MessengerError.unknownContact }
        if c.blocked { throw MessengerError.blocked }
        guard c.status == .accepted else { throw MessengerError.notAccepted }
        guard sessions.hasSession(contactId: c.id) else { throw MessengerError.cryptoFailure }
        var plain = Data([MeshMessenger.payloadKind])
        plain.append(payload)
        let cipher = try sessions.encrypt(plain, for: c.id)
        guard let env = directEnvelope(to: c, bodyType: .ciphertext, body: cipher) else { throw MessengerError.cryptoFailure }
        return node.enqueue(env)
    }

    private func transmit(_ m: inout ChatMessage, to c: Contact) {
        var plain = Data([MeshMessenger.textKind])
        plain.append(Data(m.text.utf8))
        guard let cipher = try? sessions.encrypt(plain, for: c.id),
              let env = directEnvelope(to: c, bodyType: .ciphertext, body: cipher) else {
            messages.update(id: m.id) { $0.state = .failed }
            return
        }
        let outboxId = node.enqueue(env)
        messages.update(id: m.id) { $0.state = .queued; $0.outboxId = outboxId }
        m.state = .queued
        m.outboxId = outboxId
    }

    private func flushWaiting(for contactId: String) {
        guard let c = contacts.contact(id: contactId) else { return }
        for var m in messages.waiting(for: contactId) {
            transmit(&m, to: c)
            if let fresh = messages.all().first(where: { $0.id == m.id }) { delegate?.messenger(self, didUpdate: fresh) }
        }
    }

    private func handleCiphertext(_ env: Envelope, from c: Contact, msgId: Data) {
        if c.blocked { return }
        guard let plain = try? sessions.decrypt(env.body, from: c.id, remoteIdentity: c.identityKey),
              plain.count >= 1 else { return }
        if plain[plain.startIndex] == MeshMessenger.payloadKind {
            if let secret = routingSecret(for: c) {
                var body = msgId
                body.append(RoutingTags.receiptMac(routingSecret: secret, msgId: msgId))
                if let r = directEnvelope(to: c, bodyType: .receipt, body: body) { node.enqueue(r) }
            }
            payloadHandler?(Data(plain.dropFirst()), c)
            return
        }
        guard plain[plain.startIndex] == MeshMessenger.textKind,
              let text = String(data: plain.dropFirst(), encoding: .utf8) else { return }

        let m = ChatMessage(id: UUID().uuidString, contactId: c.id, outgoing: false, text: text,
                            timestampMs: nowMs(), state: .received, outboxId: nil)
        messages.add(m)
        if let secret = routingSecret(for: c) {
            var body = msgId
            body.append(RoutingTags.receiptMac(routingSecret: secret, msgId: msgId))
            if let r = directEnvelope(to: c, bodyType: .receipt, body: body) { node.enqueue(r) }
        }
        delegate?.messenger(self, didReceive: m)
    }

    private func handleReceipt(_ env: Envelope, from c: Contact) {
        guard env.body.count == Proto.msgIdSize + 16, let secret = routingSecret(for: c) else { return }
        let msgId = Data(env.body.prefix(Proto.msgIdSize))
        let mac = Data(env.body.suffix(16))
        guard RoutingTags.receiptMac(routingSecret: secret, msgId: msgId) == mac else { return }
        let hex = msgId.toHex()
        node.markDelivered(msgIdHex: hex)
    }

    public func node(_ node: MeshNode, didReceive envelope: Envelope, msgId: Data) {
        guard let match = matchTag(envelope) else { return }
        switch (match, envelope.bodyType) {
        case (.inbox, .bundleRequest): handleRequest(envelope)
        case (.inbox, .bundle): handleBundle(envelope)
        case (.direct(let c), .ciphertext): handleCiphertext(envelope, from: c, msgId: msgId)
        case (.direct(let c), .receipt): handleReceipt(envelope, from: c)
        default: break
        }
    }

    public func node(_ node: MeshNode, outboxDidChange msgId: String, state: OutboxState) {
        guard let m = messages.message(outboxId: msgId) else { return }
        let newState: MessageState
        switch state {
        case .queued: return
        case .sent: newState = m.state == .delivered ? .delivered : .sent
        case .delivered: newState = .delivered
        case .expired: newState = .failed
        }
        messages.update(id: m.id) { $0.state = newState }
        if let fresh = messages.all().first(where: { $0.id == m.id }) { delegate?.messenger(self, didUpdate: fresh) }
    }
}
