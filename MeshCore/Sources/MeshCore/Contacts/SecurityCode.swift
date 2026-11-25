import Foundation
import CryptoKit

public enum SecurityCode {
    public static func make(localKey: Data, remoteKey: Data) -> String {
        let (a, b) = localKey.lexicographicallyPrecedes(remoteKey) ? (localKey, remoteKey) : (remoteKey, localKey)
        var material = Data("mesh-safety-v1".utf8)
        material.append(a)
        material.append(b)
        var digest = Data(SHA256.hash(data: material))

        for _ in 0..<2048 { digest = Data(SHA256.hash(data: digest + material)) }
        var groups = [String]()
        for g in 0..<6 {
            let o = g * 4
            let v = (UInt32(digest[o]) << 24) | (UInt32(digest[o + 1]) << 16) | (UInt32(digest[o + 2]) << 8) | UInt32(digest[o + 3])
            let n = String(v % 100_000)
            groups.append(String(repeating: "0", count: 5 - n.count) + n)
        }
        return groups.joined(separator: " ")
    }
}
