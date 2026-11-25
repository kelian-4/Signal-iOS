import Foundation
import CryptoKit

public final class CryptoKitIdentity: IdentityCrypto {
    private let signing: Curve25519.Signing.PrivateKey
    let agreement: Curve25519.KeyAgreement.PrivateKey

    public init(entropy: Data) throws {
        let seed = Data(HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: entropy),
            salt: Data("mesh-identity-v1".utf8),
            info: Data("ed25519+x25519".utf8),
            outputByteCount: 32
        ).withUnsafeBytes { Data($0) })
        signing = try Curve25519.Signing.PrivateKey(rawRepresentation: seed)
        agreement = try Curve25519.KeyAgreement.PrivateKey(rawRepresentation: seed)
    }

    public var publicKey: Data {
        return signing.publicKey.rawRepresentation + agreement.publicKey.rawRepresentation
    }

    public func sign(_ message: Data) -> Data {
        return (try? signing.signature(for: message)) ?? Data()
    }

    public func verify(publicKey: Data, message: Data, signature: Data) -> Bool {
        guard publicKey.count == 64,
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: Data(publicKey.prefix(32))) else { return false }
        return key.isValidSignature(signature, for: message)
    }

    public func sharedSecret(with publicKey: Data) -> Data? {
        guard publicKey.count == 64,
              let remote = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data(publicKey.suffix(32))),
              let secret = try? agreement.sharedSecretFromKeyAgreement(with: remote) else { return nil }
        return secret.withUnsafeBytes { Data($0) }
    }

    func sharedSecret(withEphemeral raw: Data) -> Data? {
        guard let remote = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: raw),
              let secret = try? agreement.sharedSecretFromKeyAgreement(with: remote) else { return nil }
        return secret.withUnsafeBytes { Data($0) }
    }
}
