import Foundation
import LibSignalClient
import MeshBLE
import MeshCore
import SignalServiceKit
import UserNotifications

final class MeshBridge: NSObject, MeshBackend, MeshServiceDelegate {
    static let shared = MeshBridge()

    private enum PayloadKind: UInt8 {
        case signalMessage = 0x01
        case bundle = 0x02
    }

    private struct Entry: Codable {
        var aci: String
        var bundle: Data
        var name: String
    }

    private struct EntryMap: Codable {
        var entries: [String: Entry] = [:]
    }

    let transport = MeshBLETransport()
    let journal: FieldJournal
    private(set) var service: MeshService!

    private let lock = NSLock()
    private var map = EntryMap()
    private var appReady = false
    private var pendingInbound: [(Data, MeshCore.Contact)] = []
    private var statusHandlers: [(BLEStatus) -> Void] = []
    private(set) var lastStatus = BLEStatus()
    var onChange: (() -> Void)?

    private override init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Mesh", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        journal = FieldJournal(directory: support)
        super.init()
        transport.logger = journal
        let created = MeshService(
            directory: support.appendingPathComponent("data", isDirectory: true),
            vault: MeshKeychainVault(),
            transport: transport,
            sessionDecorator: { [weak self] base in SignalBundleCrypto(base: base, bridge: self) },
        )
        created.logger = journal
        created.delegate = self
        service = created
        map = Documents.read(EntryMap.self, from: created.store, name: "signal-map") ?? EntryMap()
        transport.hasPendingWork = { [weak self] in self?.service.node?.hasPendingWork ?? false }
        transport.onTick = { [weak self] in self?.service.tick() }
        transport.onStatus = { [weak self] status in
            self?.lastStatus = status
            self?.statusHandlers.forEach { $0(status) }
        }
        service.messenger?.payloadHandler = { [weak self] data, contact in self?.handlePayload(data, from: contact) }
    }

    func start() {
        MeshBackendRegistry.shared.backend = self
        transport.start()
    }

    func addStatusHandler(_ handler: @escaping (BLEStatus) -> Void) {
        statusHandlers.append(handler)
        handler(lastStatus)
    }

    func markAppReady() {
        transport.queue.async {
            self.appReady = true
            let queued = self.pendingInbound
            self.pendingInbound.removeAll()
            for (data, contact) in queued { self.handlePayload(data, from: contact) }
        }
    }

    func attachMessenger() {
        service.messenger?.payloadHandler = { [weak self] data, contact in self?.handlePayload(data, from: contact) }
    }

    private func persistMap() {
        Documents.write(map, to: service.store, name: "signal-map")
    }

    private func entry(forContact id: String) -> Entry? {
        lock.lock()
        defer { lock.unlock() }
        return map.entries[id]
    }

    private func contactId(forAci aci: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return map.entries.first(where: { $0.value.aci == aci })?.key
    }

    func registerRemoteBundle(contactId: String, bundle: Data) {
        guard let identityKey = Self.identityKey(inBundle: bundle) else { return }
        let contact = service.messenger?.contacts.contact(id: contactId)
        let name = contact?.displayName ?? "Contact"
        let verified = contact?.trust == .verified
        lock.lock()
        let aciString: String
        if let existing = map.entries[contactId] {
            aciString = existing.aci
        } else {
            aciString = MeshIdentity.aci(forIdentityKey: identityKey).serviceIdString
        }
        map.entries[contactId] = Entry(aci: aciString, bundle: bundle, name: name)
        persistMap()
        lock.unlock()
        guard let aci = try? ServiceId.parseFrom(serviceIdString: aciString) as? Aci else { return }
        Task {
            await MeshSignalContacts.ensureContact(aci: aci, displayName: name, identityKey: identityKey, verified: verified)
        }
        transport.queue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.sendOwnBundle(to: contactId)
        }
        onChange?()
    }

    private func sendOwnBundle(to contactId: String) {
        guard let json = MeshLocalRegistration.localBundleJSON() else { return }
        var payload = Data([PayloadKind.bundle.rawValue])
        payload.append(json)
        _ = try? service.messenger?.sendPayload(payload, to: contactId)
    }

    private static func padded(_ text: String) -> String {
        var out = text
        while out.count % 4 != 0 { out += "=" }
        return out
    }

    private static func identityKey(inBundle bundle: Data) -> Data? {
        guard
            let obj = try? JSONSerialization.jsonObject(with: bundle) as? [String: Any],
            let text = obj["identityKey"] as? String,
            let data = Data(base64Encoded: Self.padded(text)),
            data.count == 33
        else { return nil }
        return data
    }

    private func handlePayload(_ data: Data, from contact: MeshCore.Contact) {
        guard let first = data.first, let kind = PayloadKind(rawValue: first) else { return }
        let body = Data(data.dropFirst())
        switch kind {
        case .bundle:
            registerRemoteBundle(contactId: contact.id, bundle: body)
        case .signalMessage:
            guard appReady else {
                pendingInbound.append((data, contact))
                return
            }
            guard
                body.count > 10,
                let entry = entry(forContact: contact.id),
                let senderAci = try? ServiceId.parseFrom(serviceIdString: entry.aci) as? Aci,
                let localAci = MeshLocalRegistration.localAci()
            else { return }
            let envelopeType = Int32(body[body.startIndex])
            let deviceId = UInt32(body[body.startIndex + 1])
            var timestamp: UInt64 = 0
            for i in 0..<8 { timestamp = (timestamp << 8) | UInt64(body[body.startIndex + 2 + i]) }
            let content = Data(body.dropFirst(10))
            MeshInbox.deliver(
                senderAci: senderAci,
                senderDeviceId: deviceId,
                destination: localAci,
                envelopeType: envelopeType,
                content: content,
                timestamp: timestamp,
            )
        }
    }

    func meshSend(to recipient: ServiceId, timestamp: UInt64, messages: [MeshOutboundMessage], urgent: Bool) async throws {
        guard let aci = recipient as? Aci else { throw OWSHTTPError.networkFailure(.genericFailure) }
        let aciString = aci.serviceIdString
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            transport.queue.async {
                guard let contactId = self.contactId(forAci: aciString), let messenger = self.service.messenger else {
                    continuation.resume(throwing: OWSHTTPError.networkFailure(.genericFailure))
                    return
                }
                do {
                    for message in messages {
                        var payload = Data([PayloadKind.signalMessage.rawValue, UInt8(truncatingIfNeeded: message.envelopeType), UInt8(truncatingIfNeeded: message.deviceId)])
                        for shift in stride(from: 56, through: 0, by: -8) {
                            payload.append(UInt8(truncatingIfNeeded: timestamp >> UInt64(shift)))
                        }
                        payload.append(message.content)
                        _ = try messenger.sendPayload(payload, to: contactId)
                    }
                    self.transport.connectNow()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: OWSHTTPError.networkFailure(.genericFailure))
                }
            }
        }
    }

    func meshPreKeyBundleJSON(for aci: Aci) -> Data? {
        let aciString = aci.serviceIdString
        lock.lock()
        defer { lock.unlock() }
        return map.entries.values.first(where: { $0.aci == aciString })?.bundle
    }

    func meshDidUploadPreKeys(json: Data, identity: OWSIdentity) {}

    func serviceDidChange(_ service: MeshService) {
        syncVerification()
        onChange?()
    }

    private var syncedVerified = Set<String>()

    private func syncVerification() {
        guard let contacts = service.messenger?.contacts.all() else { return }
        for contact in contacts where contact.trust == .verified && !syncedVerified.contains(contact.id) {
            guard let entry = entry(forContact: contact.id),
                  let key = Self.identityKey(inBundle: entry.bundle),
                  let aci = try? ServiceId.parseFrom(serviceIdString: entry.aci) as? Aci else { continue }
            syncedVerified.insert(contact.id)
            let name = contact.displayName
            Task {
                await MeshSignalContacts.ensureContact(aci: aci, displayName: name, identityKey: key, verified: true)
            }
        }
    }

    func service(_ service: MeshService, didReceive message: MeshCore.ChatMessage, from contact: MeshCore.Contact) {}

    func service(_ service: MeshService, contactRequestFrom contact: MeshCore.Contact) {
        notify(title: "Nouvelle demande de contact", body: contact.displayName)
    }

    func service(_ service: MeshService, keyChangedFor contact: MeshCore.Contact) {
        notify(title: "Clé de sécurité modifiée", body: contact.displayName)
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    func aci(forContact id: String) -> Aci? {
        guard let e = entry(forContact: id) else { return nil }
        return try? ServiceId.parseFrom(serviceIdString: e.aci) as? Aci
    }
}

final class SignalBundleCrypto: SessionCrypto {
    private let base: SessionCrypto
    private weak var bridge: MeshBridge?

    init(base: SessionCrypto, bridge: MeshBridge?) {
        self.base = base
        self.bridge = bridge
    }

    func makeBundle() throws -> Data {
        guard let json = MeshLocalRegistration.localBundleJSON() else { throw MessengerError.cryptoFailure }
        return json
    }

    func startSession(contactId: String, remoteIdentity: Data, bundle: Data) throws {
        try base.startSession(contactId: contactId, remoteIdentity: remoteIdentity, bundle: bundle)
        bridge?.registerRemoteBundle(contactId: contactId, bundle: bundle)
    }

    func hasSession(contactId: String) -> Bool {
        return base.hasSession(contactId: contactId)
    }

    func encrypt(_ plaintext: Data, for contactId: String) throws -> Data {
        return try base.encrypt(plaintext, for: contactId)
    }

    func decrypt(_ ciphertext: Data, from contactId: String, remoteIdentity: Data) throws -> Data {
        return try base.decrypt(ciphertext, from: contactId, remoteIdentity: remoteIdentity)
    }

    func resetAllSessions() {
        base.resetAllSessions()
    }
}
