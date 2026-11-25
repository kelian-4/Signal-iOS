import Foundation
import CryptoKit

public final class EphemeralSessionCrypto: SessionCrypto {
    private struct State: Codable {
        var remoteKeys: [String: Data] = [:]
    }

    private let identity: CryptoKitIdentity
    private let store: DocumentStore
    private var state: State
    private let lock = NSLock()

    public init(identity: CryptoKitIdentity, store: DocumentStore) {
        self.identity = identity
        self.store = store
        self.state = Documents.read(State.self, from: store, name: "sessions") ?? State()
    }

    private func persist() { Documents.write(state, to: store, name: "sessions") }

    private func derive(shared: Data, staticShared: Data, ephemeralPublic: Data) -> SymmetricKey {
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: shared + staticShared),
            salt: ephemeralPublic,
            info: Data("mesh-message-v1".utf8),
            outputByteCount: 32
        )
    }

    public func makeBundle() throws -> Data {
        return Data((0..<32).map { _ in UInt8.random(in: 0...255) })
    }

    public func startSession(contactId: String, remoteIdentity: Data, bundle: Data) throws {
        guard remoteIdentity.count == 64 else { throw MessengerError.cryptoFailure }
        lock.lock()
        state.remoteKeys[contactId] = remoteIdentity
        persist()
        lock.unlock()
    }

    public func hasSession(contactId: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return state.remoteKeys[contactId] != nil
    }

    public func encrypt(_ plaintext: Data, for contactId: String) throws -> Data {
        lock.lock()
        let remote = state.remoteKeys[contactId]
        lock.unlock()
        guard let remoteKey = remote,
              let staticShared = identity.sharedSecret(with: remoteKey),
              let remoteAgreement = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data(remoteKey.suffix(32)))
        else { throw MessengerError.cryptoFailure }
        let ephemeral = Curve25519.KeyAgreement.PrivateKey()
        guard let dh = try? ephemeral.sharedSecretFromKeyAgreement(with: remoteAgreement) else {
            throw MessengerError.cryptoFailure
        }
        let ephPub = ephemeral.publicKey.rawRepresentation
        let key = derive(shared: dh.withUnsafeBytes { Data($0) }, staticShared: staticShared, ephemeralPublic: ephPub)
        let box = try ChaChaPoly.seal(plaintext, using: key, authenticating: ephPub)
        return ephPub + box.combined
    }

    public func decrypt(_ ciphertext: Data, from contactId: String, remoteIdentity: Data) throws -> Data {
        guard ciphertext.count > 32 + 12 + 16, remoteIdentity.count == 64 else { throw MessengerError.cryptoFailure }
        let ephPub = Data(ciphertext.prefix(32))
        guard let dh = identity.sharedSecret(withEphemeral: ephPub),
              let staticShared = identity.sharedSecret(with: remoteIdentity) else { throw MessengerError.cryptoFailure }
        let key = derive(shared: dh, staticShared: staticShared, ephemeralPublic: ephPub)
        let plain: Data
        do {
            let box = try ChaChaPoly.SealedBox(combined: Data(ciphertext.dropFirst(32)))
            plain = try ChaChaPoly.open(box, using: key, authenticating: ephPub)
        } catch {
            throw MessengerError.cryptoFailure
        }
        lock.lock()
        if state.remoteKeys[contactId] == nil {
            state.remoteKeys[contactId] = remoteIdentity
            persist()
        }
        lock.unlock()
        return plain
    }

    public func resetAllSessions() {
        lock.lock()
        state.remoteKeys.removeAll()
        persist()
        lock.unlock()
    }
}
