import Foundation

struct ByteWriter {
    private(set) var data = Data()

    mutating func u8(_ v: UInt8) { data.append(v) }

    mutating func u16(_ v: Int) {
        data.append(UInt8((v >> 8) & 0xFF))
        data.append(UInt8(v & 0xFF))
    }

    mutating func i64(_ v: Int64) {
        let u = UInt64(bitPattern: v)
        for i in stride(from: 7, through: 0, by: -1) {
            data.append(UInt8((u >> UInt64(i * 8)) & 0xFF))
        }
    }

    mutating func raw(_ d: Data) { data.append(d) }

    mutating func bytes8(_ d: Data) {
        data.append(UInt8(d.count))
        data.append(d)
    }

    mutating func bytes16(_ d: Data) {
        u16(d.count)
        data.append(d)
    }
}

struct ByteReader {
    private let bytes: [UInt8]
    private var pos = 0

    init(_ data: Data) { bytes = [UInt8](data) }

    var remaining: Int { return bytes.count - pos }

    mutating func u8() -> UInt8? {
        guard remaining >= 1 else { return nil }
        defer { pos += 1 }
        return bytes[pos]
    }

    mutating func u16() -> Int? {
        guard remaining >= 2 else { return nil }
        defer { pos += 2 }
        return (Int(bytes[pos]) << 8) | Int(bytes[pos + 1])
    }

    mutating func i64() -> Int64? {
        guard remaining >= 8 else { return nil }
        var u: UInt64 = 0
        for i in 0..<8 { u = (u << 8) | UInt64(bytes[pos + i]) }
        pos += 8
        return Int64(bitPattern: u)
    }

    mutating func raw(_ n: Int) -> Data? {
        guard n >= 0, remaining >= n else { return nil }
        defer { pos += n }
        return Data(bytes[pos..<pos + n])
    }

    mutating func bytes8() -> Data? {
        guard let n = u8() else { return nil }
        return raw(Int(n))
    }

    mutating func bytes16() -> Data? {
        guard let n = u16() else { return nil }
        return raw(n)
    }
}

extension Data {
    func base64URLEncoded() -> String {
        return base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URL s: String) {
        var b = s.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while b.count % 4 != 0 { b += "=" }
        self.init(base64Encoded: b)
    }
}
