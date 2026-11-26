import CryptoKit
import Foundation
public import LibSignalClient

public enum MeshLocalRegistration {
    public enum RegistrationError: Error {
        case keyDerivationFailed
        case alreadyRegistered
    }

    public static func derivePrivateKeyBytes(fromEntropy entropy: Data) -> Data {
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: entropy),
            salt: Data("mesh-identity-v1".utf8),
            info: Data("signal-aci-identity".utf8),
            outputByteCount: 32,
        )
        return key.withUnsafeBytes { Data($0) }
    }

    public static func identityKeyPair(fromEntropy entropy: Data) throws -> IdentityKeyPair {
        let privateKey = try PrivateKey(derivePrivateKeyBytes(fromEntropy: entropy))
        return IdentityKeyPair(publicKey: privateKey.publicKey, privateKey: privateKey)
    }

    public static var isRegistered: Bool {
        let bridge = DependenciesBridge.shared
        return bridge.db.read { tx in
            bridge.tsAccountManager.registrationState(tx: tx).isRegistered
        }
    }

    @discardableResult
    public static func register(entropy: Data) async throws -> Aci {
        let bridge = DependenciesBridge.shared
        let keyPair = try identityKeyPair(fromEntropy: entropy)
        let aci = MeshIdentity.aci(forIdentityKey: keyPair.publicKey.serialize())
        let salt = try AuthCredentialSalt(rawValue: Data((0..<16).map { _ in UInt8.random(in: 0...255) }))
        let registrationId = RegistrationIdGenerator.generate()
        let authPassword = Data((0..<18).map { _ in UInt8.random(in: 0...255) }).base64EncodedString()

        await bridge.db.awaitableWrite { tx in
            bridge.identityManager.setIdentityKeyPair(ECKeyPair(keyPair), for: .aci, tx: tx)
            bridge.tsAccountManager.setRegistrationId(registrationId, for: .aci, tx: tx)
        }

        let preKeyBundle = await bridge.preKeyManager.createPreKeysForRegistration(forIdentity: .aci)
        storeInitialBundle(preKeyBundle)

        await bridge.db.awaitableWrite { tx in
            bridge.registrationStateChangeManager.didRegisterOrProvision(
                account: AuthedAccount.Explicit(
                    aci: aci,
                    accountType: .phoneNumberless(salt),
                    deviceId: .primary,
                    authPassword: authPassword,
                ),
                tx: tx,
            )
        }
        await bridge.preKeyManager.finalizeRegistrationPreKeyBundle(preKeyBundle)
        return aci
    }

    private static func storeInitialBundle(_ bundle: RegistrationPreKeyUploadBundle) {
        var upload: [String: Any] = [:]
        let signed = bundle.signedPreKey
        upload["signedPreKey"] = [
            "keyId": signed.id,
            "publicKey": (try? signed.publicKey().serialize().base64EncodedStringWithoutPadding()) ?? "",
            "signature": signed.signature.base64EncodedStringWithoutPadding(),
        ]
        let kyber = bundle.lastResortPreKey
        upload["pqLastResortPreKey"] = [
            "keyId": kyber.id,
            "publicKey": (try? kyber.publicKey().serialize().base64EncodedStringWithoutPadding()) ?? "",
            "signature": kyber.signature.base64EncodedStringWithoutPadding(),
        ]
        if let data = try? JSONSerialization.data(withJSONObject: upload) {
            MeshPreKeyStore.shared.merge(uploadJSON: data)
        }
    }

    public static func localBundleJSON() -> Data? {
        let bridge = DependenciesBridge.shared
        return bridge.db.read { tx -> Data? in
            guard
                let pair = bridge.identityManager.identityKeyPair(for: .aci, tx: tx),
                let registrationId = bridge.tsAccountManager.getRegistrationId(for: .aci, tx: tx)
            else {
                return nil
            }
            return MeshPreKeyStore.shared.bundleJSON(
                identityKey: pair.keyPair.publicKey.serialize(),
                registrationId: registrationId,
            )
        }
    }

    public static func localIdentityPublicKey() -> Data? {
        let bridge = DependenciesBridge.shared
        return bridge.db.read { tx -> Data? in
            return bridge.identityManager.identityKeyPair(for: .aci, tx: tx)?.keyPair.publicKey.serialize()
        }
    }

    public static func localAci() -> Aci? {
        let bridge = DependenciesBridge.shared
        return bridge.db.read { tx in
            bridge.tsAccountManager.localIdentifiers(tx: tx)?.aci
        }
    }
}
