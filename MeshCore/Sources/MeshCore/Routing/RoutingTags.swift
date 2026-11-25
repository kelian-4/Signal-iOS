import Foundation
import CryptoKit

public enum RoutingTags {
    public static let epochMs: Int64 = 3_600_000
    public static let tagSize = 8

    public static func epoch(atMs ms: Int64) -> Int64 {
        return ms / epochMs
    }

    public static func acceptedEpochs(nowMs: Int64) -> [Int64] {
        let e = epoch(atMs: nowMs)
        return [e - 1, e, e + 1]
    }

    private static func epochBytes(_ epoch: Int64) -> Data {
        var out = Data()
        var v = UInt64(bitPattern: epoch)
        var bytes = [UInt8](repeating: 0, count: 8)
        for i in stride(from: 7, through: 0, by: -1) {
            bytes[i] = UInt8(v & 0xFF)
            v >>= 8
        }
        out.append(contentsOf: bytes)
        return out
    }

    private static func hmac(key: Data, message: Data) -> Data {
        let mac = HMAC<SHA256>.authenticationCode(for: message, using: SymmetricKey(data: key))
        return Data(mac)
    }

    public static func routingSecret(fromSharedSecret shared: Data) -> Data {
        let key = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: shared),
            salt: Data(),
            info: Data("mesh-routing-v1".utf8),
            outputByteCount: 32
        )
        return key.withUnsafeBytes { Data($0) }
    }

    public static func directTag(routingSecret: Data, recipientPublic: Data, epoch: Int64) -> Data {
        var msg = Data("mesh-direct".utf8)
        msg.append(recipientPublic)
        msg.append(epochBytes(epoch))
        return hmac(key: routingSecret, message: msg).prefix(tagSize).withUnsafeBytes { Data($0) }
    }

    public static func inboxTag(identityPublic: Data, epoch: Int64) -> Data {
        let key = Data(SHA256.hash(data: Data("mesh-inbox-key".utf8) + identityPublic))
        var msg = Data("mesh-inbox".utf8)
        msg.append(epochBytes(epoch))
        return hmac(key: key, message: msg).prefix(tagSize).withUnsafeBytes { Data($0) }
    }

    public static func receiptMac(routingSecret: Data, msgId: Data) -> Data {
        var msg = Data("mesh-receipt".utf8)
        msg.append(msgId)
        return hmac(key: routingSecret, message: msg).prefix(16).withUnsafeBytes { Data($0) }
    }
}
