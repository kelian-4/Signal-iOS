import Foundation
import CryptoKit

public enum Bip39Error: Error, Equatable {
    case invalidEntropyLength
    case invalidWordCount
    case unknownWord(String)
    case badChecksum
}

public enum Bip39 {
    private static let indexByWord: [String: Int] = {
        var map = [String: Int]()
        for (i, w) in Bip39Words.english.enumerated() { map[w] = i }
        return map
    }()

    public static func mnemonic(fromEntropy entropy: Data) throws -> [String] {
        let n = entropy.count
        guard n >= 16 && n <= 32 && n % 4 == 0 else { throw Bip39Error.invalidEntropyLength }
        let checksumBits = n * 8 / 32
        let digest = Array(SHA256.hash(data: entropy))
        var bits = [UInt8]()
        bits.reserveCapacity(n * 8 + checksumBits)
        for byte in entropy {
            for i in stride(from: 7, through: 0, by: -1) {
                bits.append((byte >> UInt8(i)) & 1)
            }
        }
        for i in 0..<checksumBits {
            bits.append((digest[0] >> UInt8(7 - i)) & 1)
        }
        var words = [String]()
        var pos = 0
        while pos < bits.count {
            var idx = 0
            for j in 0..<11 {
                idx = (idx << 1) | Int(bits[pos + j])
            }
            words.append(Bip39Words.english[idx])
            pos += 11
        }
        return words
    }

    public static func normalize(_ phrase: String) -> [String] {
        return phrase
            .lowercased()
            .split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "\r" })
            .map { String($0) }
    }

    public static func entropy(fromMnemonic words: [String]) throws -> Data {
        let count = words.count
        guard count >= 12 && count <= 24 && count % 3 == 0 else { throw Bip39Error.invalidWordCount }
        var bits = [UInt8]()
        bits.reserveCapacity(count * 11)
        for w in words {
            guard let idx = indexByWord[w] else { throw Bip39Error.unknownWord(w) }
            for i in stride(from: 10, through: 0, by: -1) {
                bits.append(UInt8((idx >> i) & 1))
            }
        }
        let totalBits = count * 11
        let entropyBits = totalBits * 32 / 33
        let checksumBits = totalBits - entropyBits
        var entropy = Data()
        var pos = 0
        while pos < entropyBits {
            var byte: UInt8 = 0
            for j in 0..<8 {
                byte = (byte << 1) | bits[pos + j]
            }
            entropy.append(byte)
            pos += 8
        }
        let digest = Array(SHA256.hash(data: entropy))
        for i in 0..<checksumBits {
            let expected = (digest[0] >> UInt8(7 - i)) & 1
            if bits[entropyBits + i] != expected { throw Bip39Error.badChecksum }
        }
        return entropy
    }
}
