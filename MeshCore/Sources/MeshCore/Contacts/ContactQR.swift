import Foundation

public struct ContactQR: Equatable {
    public static let prefix = "mesh1:"
    public static let version: UInt8 = 1
    public static let maxNameBytes = 32

    public static let maxAgeMs: Int64 = 10 * 60 * 1000

    public let identityKey: Data
    public let displayName: String
    public let timestampMs: Int64
    public let signature: Data

    public init(identityKey: Data, displayName: String, timestampMs: Int64, signature: Data) {
        self.identityKey = identityKey
        self.displayName = displayName
        self.timestampMs = timestampMs
        self.signature = signature
    }

    static func clampName(_ name: String) -> Data {
        var out = Data()
        for ch in name {
            let part = Data(String(ch).utf8)
            if out.count + part.count > maxNameBytes { break }
            out.append(part)
        }
        return out
    }

    private static func body(identityKey: Data, name: Data, timestampMs: Int64) -> Data {
        var w = ByteWriter()
        w.u8(version)
        w.bytes8(identityKey)
        w.i64(timestampMs)
        w.bytes8(name)
        return w.data
    }

    private static func signedMessage(_ body: Data) -> Data {
        return Data("mesh-qr-v1".utf8) + body
    }

    public static func make(crypto: IdentityCrypto, displayName: String, nowMs: Int64) -> ContactQR {
        let name = clampName(displayName)
        let b = body(identityKey: crypto.publicKey, name: name, timestampMs: nowMs)
        let sig = crypto.sign(signedMessage(b))
        return ContactQR(identityKey: crypto.publicKey,
                         displayName: String(decoding: name, as: UTF8.self),
                         timestampMs: nowMs, signature: sig)
    }

    public func encode() -> String {
        let name = ContactQR.clampName(displayName)
        var w = ByteWriter()
        w.raw(ContactQR.body(identityKey: identityKey, name: name, timestampMs: timestampMs))
        w.bytes8(signature)
        return ContactQR.prefix + w.data.base64URLEncoded()
    }

    public static func decode(_ text: String) -> ContactQR? {
        guard text.hasPrefix(prefix), let raw = Data(base64URL: String(text.dropFirst(prefix.count))) else { return nil }
        var r = ByteReader(raw)
        guard let v = r.u8(), v == version,
              let key = r.bytes8(), !key.isEmpty,
              let ts = r.i64(),
              let nameData = r.bytes8(), nameData.count <= maxNameBytes,
              let sig = r.bytes8(), !sig.isEmpty,
              r.remaining == 0,
              let name = String(data: nameData, encoding: .utf8) else { return nil }
        return ContactQR(identityKey: key, displayName: name, timestampMs: ts, signature: sig)
    }

    public func verify(crypto: IdentityCrypto, nowMs: Int64) -> Bool {
        let age = nowMs - timestampMs
        if age > ContactQR.maxAgeMs || age < -ContactQR.maxAgeMs { return false }
        let b = ContactQR.body(identityKey: identityKey, name: ContactQR.clampName(displayName), timestampMs: timestampMs)
        return crypto.verify(publicKey: identityKey, message: ContactQR.signedMessage(b), signature: signature)
    }
}
