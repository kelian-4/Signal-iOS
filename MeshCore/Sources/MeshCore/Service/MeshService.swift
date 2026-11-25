import Foundation

public protocol SeedVault: AnyObject {
    func loadEntropy() -> Data?
    func saveEntropy(_ entropy: Data) -> Bool
    func deleteEntropy()
}

public final class MemorySeedVault: SeedVault {
    private var value: Data?
    public init() {}
    public func loadEntropy() -> Data? { return value }
    public func saveEntropy(_ entropy: Data) -> Bool { value = entropy; return true }
    public func deleteEntropy() { value = nil }
}

public enum ServiceError: Error, Equatable {
    case noIdentity
    case identityAlreadyExists
    case vaultFailure
    case invalidName
}

public protocol MeshServiceDelegate: AnyObject {
    func serviceDidChange(_ service: MeshService)
    func service(_ service: MeshService, didReceive message: ChatMessage, from contact: Contact)
    func service(_ service: MeshService, contactRequestFrom contact: Contact)
    func service(_ service: MeshService, keyChangedFor contact: Contact)
}

public final class MeshService: MessengerDelegate {
    private struct Profile: Codable {
        var displayName: String
    }

    public static let maxNameLength = 32

    public let transport: Transport
    public let directory: URL
    public weak var delegate: MeshServiceDelegate?
    public var logger: MeshLogger = NullLogger()

    private let vault: SeedVault
    private let nowMs: NowMs
    private let config: MeshNode.Config
    private(set) public var store: DocumentStore
    private(set) public var node: MeshNode?
    private(set) public var messenger: MeshMessenger?
    private var entropy: Data?
    private var identity: CryptoKitIdentity?

    public init(directory: URL, vault: SeedVault, transport: Transport,
                config: MeshNode.Config = MeshNode.Config(), now: @escaping NowMs = systemNowMs) {
        self.directory = directory
        self.vault = vault
        self.transport = transport
        self.config = config
        self.nowMs = now
        self.store = FileDocumentStore(directory: directory)
        if let stored = vault.loadEntropy() { activate(entropy: stored) }
    }

    public var hasIdentity: Bool { return messenger != nil }

    public var displayName: String { return messenger?.displayName ?? "" }

    public var publicKey: Data? { return identity?.publicKey }

    public func recoveryWords() -> [String]? {
        guard let e = entropy else { return nil }
        return try? Bip39.mnemonic(fromEntropy: e)
    }

    private func clampName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { throw ServiceError.invalidName }
        return String(trimmed.prefix(MeshService.maxNameLength))
    }

    @discardableResult
    public func createIdentity(displayName: String) throws -> [String] {
        guard !hasIdentity else { throw ServiceError.identityAlreadyExists }
        let name = try clampName(displayName)
        var bytes = [UInt8](repeating: 0, count: 32)
        for i in 0..<32 { bytes[i] = UInt8.random(in: 0...255) }
        let fresh = Data(bytes)
        guard vault.saveEntropy(fresh) else { throw ServiceError.vaultFailure }
        Documents.write(Profile(displayName: name), to: store, name: "profile")
        activate(entropy: fresh)
        return try Bip39.mnemonic(fromEntropy: fresh)
    }

    public func restoreIdentity(words: [String], displayName: String?) throws {
        guard !hasIdentity else { throw ServiceError.identityAlreadyExists }
        let restored = try Bip39.entropy(fromMnemonic: words)
        guard vault.saveEntropy(restored) else { throw ServiceError.vaultFailure }
        let name = try clampName(displayName ?? "Moi")
        Documents.write(Profile(displayName: name), to: store, name: "profile")
        activate(entropy: restored)
    }

    private func activate(entropy: Data) {
        guard let id = try? CryptoKitIdentity(entropy: entropy) else { return }
        self.entropy = entropy
        self.identity = id
        let name = Documents.read(Profile.self, from: store, name: "profile")?.displayName ?? "Moi"
        let sessions = EphemeralSessionCrypto(identity: id, store: store)
        let node = MeshNode(transport: transport, outbox: Outbox(store: store), relay: RelayCache(),
                            config: config, now: nowMs)
        node.logger = logger
        let messenger = MeshMessenger(
            crypto: id, sessions: sessions, node: node, contacts: ContactBook(store: store),
            abuse: AbuseGuard(store: store), messages: MessageLog(store: store), store: store,
            displayName: name, now: nowMs)
        messenger.delegate = self
        self.node = node
        self.messenger = messenger
    }

    public func rename(to newName: String) throws {
        guard let m = messenger else { throw ServiceError.noIdentity }
        let name = try clampName(newName)
        m.displayName = name
        Documents.write(Profile(displayName: name), to: store, name: "profile")
        delegate?.serviceDidChange(self)
    }

    public func tick() {
        node?.tick()
    }

    public func exportBackup() throws -> Data {
        guard let m = messenger, let e = entropy else { throw ServiceError.noIdentity }
        let payload = BackupPayload(displayName: m.displayName, contacts: m.contacts.all(),
                                    messages: m.messages.exportData(), createdMs: nowMs())
        return try RecoveryBackup.seal(try payload.encode(), entropy: e)
    }

    public func importBackup(_ file: Data) throws {
        guard let m = messenger, let e = entropy else { throw ServiceError.noIdentity }
        let payload = try BackupPayload.decode(try RecoveryBackup.open(file, entropy: e))
        m.contacts.replaceAll(payload.contacts)
        m.messages.replaceAll(MessageLog.decode(payload.messages))
        m.sessions.resetAllSessions()
        if let name = try? clampName(payload.displayName) { try? rename(to: name) }
        delegate?.serviceDidChange(self)
    }

    public func wipeEverything() {
        vault.deleteEntropy()
        for name in ["profile", "contacts", "messages", "abuse", "handshake", "sessions", "outbox"] {
            store.remove(name)
        }
        messenger = nil
        node = nil
        identity = nil
        entropy = nil
        delegate?.serviceDidChange(self)
    }

    public func messenger(_ m: MeshMessenger, didReceive message: ChatMessage) {
        if let c = m.contacts.contact(id: message.contactId) { delegate?.service(self, didReceive: message, from: c) }
        delegate?.serviceDidChange(self)
    }

    public func messenger(_ m: MeshMessenger, didUpdate message: ChatMessage) {
        delegate?.serviceDidChange(self)
    }

    public func messenger(_ m: MeshMessenger, contactRequestFrom contact: Contact) {
        delegate?.service(self, contactRequestFrom: contact)
        delegate?.serviceDidChange(self)
    }

    public func messenger(_ m: MeshMessenger, didUpdate contact: Contact) {
        delegate?.serviceDidChange(self)
    }

    public func messenger(_ m: MeshMessenger, keyChangedFor contact: Contact) {
        delegate?.service(self, keyChangedFor: contact)
        delegate?.serviceDidChange(self)
    }
}
