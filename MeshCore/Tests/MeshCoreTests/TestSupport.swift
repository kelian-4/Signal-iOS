import Foundation
import CryptoKit
import XCTest
@testable import MeshCore

final class SoftIdentityCrypto: IdentityCrypto {
    let signing: Curve25519.Signing.PrivateKey
    let agreement: Curve25519.KeyAgreement.PrivateKey

    init(seed: Data) {
        signing = try! Curve25519.Signing.PrivateKey(rawRepresentation: seed)
        agreement = try! Curve25519.KeyAgreement.PrivateKey(rawRepresentation: seed)
    }

    convenience init() {
        self.init(seed: Data((0..<32).map { _ in UInt8.random(in: 0...255) }))
    }

    var publicKey: Data { return signing.publicKey.rawRepresentation + agreement.publicKey.rawRepresentation }

    func sign(_ message: Data) -> Data { return try! signing.signature(for: message) }

    func verify(publicKey: Data, message: Data, signature: Data) -> Bool {
        guard publicKey.count == 64,
              let k = try? Curve25519.Signing.PublicKey(rawRepresentation: Data(publicKey.prefix(32))) else { return false }
        return k.isValidSignature(signature, for: message)
    }

    func sharedSecret(with publicKey: Data) -> Data? {
        guard publicKey.count == 64,
              let remote = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data(publicKey.suffix(32))),
              let ss = try? agreement.sharedSecretFromKeyAgreement(with: remote) else { return nil }
        return ss.withUnsafeBytes { Data($0) }
    }
}

final class SoftSessionCrypto: SessionCrypto {
    private let identity: SoftIdentityCrypto
    private var established = Set<String>()
    var bundlesMade = 0

    init(identity: SoftIdentityCrypto) { self.identity = identity }

    private func key(_ remote: Data) throws -> SymmetricKey {
        guard let shared = identity.sharedSecret(with: remote) else { throw MessengerError.cryptoFailure }
        return HKDF<SHA256>.deriveKey(inputKeyMaterial: SymmetricKey(data: shared), salt: Data(),
                                      info: Data("soft-session".utf8), outputByteCount: 32)
    }

    func makeBundle() throws -> Data {
        bundlesMade += 1
        return Data((0..<32).map { _ in UInt8.random(in: 0...255) })
    }

    func startSession(contactId: String, remoteIdentity: Data, bundle: Data) throws {
        _ = try key(remoteIdentity)
        remoteKeys[contactId] = remoteIdentity
        established.insert(contactId)
    }

    func hasSession(contactId: String) -> Bool { return established.contains(contactId) }

    private var remoteKeys: [String: Data] = [:]

    func rememberRemote(contactId: String, key: Data) { remoteKeys[contactId] = key }

    func encrypt(_ plaintext: Data, for contactId: String) throws -> Data {
        guard let remote = remoteKeys[contactId] else { throw MessengerError.cryptoFailure }
        return try ChaChaPoly.seal(plaintext, using: try key(remote)).combined
    }

    func decrypt(_ ciphertext: Data, from contactId: String, remoteIdentity: Data) throws -> Data {
        let box = try ChaChaPoly.SealedBox(combined: ciphertext)
        let plain = try ChaChaPoly.open(box, using: try key(remoteIdentity))
        established.insert(contactId)
        remoteKeys[contactId] = remoteIdentity
        return plain
    }

    func resetAllSessions() { established.removeAll() }
}

final class TestClock {
    var ms: Int64 = 1_800_000_000_000
    func now() -> Int64 { return ms }
}

final class SimTransport: Transport {
    weak var delegate: TransportDelegate?
    let name: String
    weak var network: SimNetwork?
    var resets: [String] = []

    init(name: String) { self.name = name }

    func send(_ frame: Data, on linkId: String) -> Bool {
        return network?.deliver(from: self, link: linkId, frame: frame) ?? false
    }

    func reset(link linkId: String) {
        resets.append(linkId)
        network?.cut(linkId)
    }
}

final class SimNetwork {
    private struct Pending { let to: SimTransport; let link: String; let data: Data }
    private var queue: [Pending] = []
    private var links: [String: (a: SimTransport, b: SimTransport)] = [:]

    var frozen = Set<String>()

    var dropFilter: ((Data) -> Bool)?
    private(set) var framesSent = 0

    @discardableResult
    func connect(_ a: SimTransport, _ b: SimTransport, mtu: Int = 185) -> String {
        a.network = self
        b.network = self
        let id = "\(a.name)<->\(b.name)"
        links[id] = (a, b)
        a.delegate?.transportDidConnect(link: id, maxFrameSize: mtu)
        b.delegate?.transportDidConnect(link: id, maxFrameSize: mtu)
        return id
    }

    func cut(_ id: String) {
        guard let l = links.removeValue(forKey: id) else { return }
        queue.removeAll { $0.link == id }
        l.a.delegate?.transportDidDisconnect(link: id)
        l.b.delegate?.transportDidDisconnect(link: id)
    }

    func deliver(from: SimTransport, link: String, frame: Data) -> Bool {
        guard let l = links[link] else { return false }
        framesSent += 1
        if let drop = dropFilter, drop(frame) { return true }
        queue.append(Pending(to: l.a === from ? l.b : l.a, link: link, data: frame))
        return true
    }

    func pump(maxSteps: Int = 100_000) {
        var steps = 0
        while !queue.isEmpty && steps < maxSteps {
            let p = queue.removeFirst()
            steps += 1
            if frozen.contains(p.to.name) { continue }
            p.to.delegate?.transportDidReceive(p.data, on: p.link)
        }
    }
}

final class Device: MessengerDelegate {
    let name: String
    let clock: TestClock
    let crypto: SoftIdentityCrypto
    let sessions: SoftSessionCrypto
    let transport: SimTransport
    let store: MemoryDocumentStore
    let node: MeshNode
    let messenger: MeshMessenger

    var received: [ChatMessage] = []
    var requests: [Contact] = []
    var keyChanges: [Contact] = []
    var updatedMessages: [ChatMessage] = []

    init(name: String, clock: TestClock, seed: Data? = nil, store: MemoryDocumentStore = MemoryDocumentStore(),
         displayName: String? = nil, config: MeshNode.Config = MeshNode.Config()) {
        let crypto = seed.map { SoftIdentityCrypto(seed: $0) } ?? SoftIdentityCrypto()
        let sessions = SoftSessionCrypto(identity: crypto)
        let transport = SimTransport(name: name)
        let node = MeshNode(transport: transport, outbox: Outbox(store: store), relay: RelayCache(),
                            config: config, now: clock.now)
        let messenger = MeshMessenger(
            crypto: crypto, sessions: sessions, node: node, contacts: ContactBook(store: store),
            abuse: AbuseGuard(store: store), messages: MessageLog(store: store), store: store,
            displayName: displayName ?? name, now: clock.now)
        self.name = name
        self.clock = clock
        self.crypto = crypto
        self.sessions = sessions
        self.transport = transport
        self.store = store
        self.node = node
        self.messenger = messenger
        messenger.delegate = self
    }

    func messenger(_ m: MeshMessenger, didReceive message: ChatMessage) { received.append(message) }
    func messenger(_ m: MeshMessenger, didUpdate message: ChatMessage) { updatedMessages.append(message) }
    func messenger(_ m: MeshMessenger, contactRequestFrom contact: Contact) { requests.append(contact) }
    func messenger(_ m: MeshMessenger, didUpdate contact: Contact) {
        sessions.rememberRemote(contactId: contact.id, key: contact.identityKey)
    }
    func messenger(_ m: MeshMessenger, keyChangedFor contact: Contact) { keyChanges.append(contact) }

    func contact(named n: String) -> Contact? {
        return messenger.contacts.all().first { $0.displayName == n }
    }
}

func makeVerifiedPair(net: SimNetwork, clock: TestClock) -> (a: Device, b: Device) {
    let a = Device(name: "alice", clock: clock)
    let b = Device(name: "bob", clock: clock)
    net.connect(a.transport, b.transport)
    try! a.messenger.addContact(fromQR: b.messenger.myQR())
    net.pump()
    let reqId = b.requests.first!.id
    try! b.messenger.acceptRequest(contactId: reqId)
    net.pump()
    return (a, b)
}
