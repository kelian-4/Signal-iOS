import Foundation
import CryptoKit

public enum BackupError: Error, Equatable {
    case badFormat
    case wrongPhraseOrCorrupted
}

public enum RecoveryBackup {
    static let magic = Data("MSHB1".utf8)

    public static func key(fromEntropy entropy: Data) -> SymmetricKey {
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: entropy),
            salt: Data("mesh-backup-v1".utf8),
            info: Data("backup-encryption".utf8),
            outputByteCount: 32
        )
    }

    public static func seal(_ plaintext: Data, entropy: Data) throws -> Data {
        let box = try ChaChaPoly.seal(plaintext, using: key(fromEntropy: entropy), authenticating: magic)
        return magic + box.combined
    }

    public static func open(_ file: Data, entropy: Data) throws -> Data {
        guard file.count > magic.count + 12 + 16, file.prefix(magic.count) == magic else { throw BackupError.badFormat }
        let sealed = file.dropFirst(magic.count)
        do {
            let box = try ChaChaPoly.SealedBox(combined: Data(sealed))
            return try ChaChaPoly.open(box, using: key(fromEntropy: entropy), authenticating: magic)
        } catch {
            throw BackupError.wrongPhraseOrCorrupted
        }
    }
}

public struct BackupPayload: Codable, Equatable {
    public var version: Int
    public var displayName: String
    public var contacts: [Contact]
    public var messages: Data
    public var createdMs: Int64

    public init(version: Int = 1, displayName: String, contacts: [Contact], messages: Data, createdMs: Int64) {
        self.version = version
        self.displayName = displayName
        self.contacts = contacts
        self.messages = messages
        self.createdMs = createdMs
    }

    public func encode() throws -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        return try enc.encode(self)
    }

    public static func decode(_ data: Data) throws -> BackupPayload {
        return try JSONDecoder().decode(BackupPayload.self, from: data)
    }
}
