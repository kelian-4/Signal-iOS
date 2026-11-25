import Foundation

extension Data {

    public func toHex() -> String {
        var out = ""
        out.reserveCapacity(count * 2)
        for byte in self {
            let s = String(byte, radix: 16)
            out += (s.count == 1) ? "0" + s : s
        }
        return out
    }

    public init?(meshHex hex: String) {
        let chars = Array(hex.utf8)
        if chars.count % 2 != 0 { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(chars.count / 2)
        var i = 0
        while i < chars.count {
            guard let hi = Data.nibble(chars[i]), let lo = Data.nibble(chars[i + 1]) else { return nil }
            bytes.append(UInt8(hi << 4 | lo))
            i += 2
        }
        self.init(bytes)
    }

    private static func nibble(_ c: UInt8) -> Int? {
        switch c {
        case 48...57: return Int(c) - 48
        case 97...102: return Int(c) - 97 + 10
        case 65...70: return Int(c) - 65 + 10
        default: return nil
        }
    }
}
