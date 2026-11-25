import Foundation

public enum EnvelopeKind: UInt8 {

    case direct = 1

    case inbox = 2
}

public enum BodyType: UInt8 {

    case ciphertext = 1

    case bundleRequest = 2

    case bundle = 3

    case receipt = 4
}

public struct Envelope: Equatable {
    public static let version: UInt8 = 1
    public static let headerSize = 12
    public static let maxBodySize = 16 * 1024

    public let kind: EnvelopeKind
    public let bodyType: BodyType
    public let ttl: UInt8
    public let tag: Data
    public let body: Data

    public init(kind: EnvelopeKind, bodyType: BodyType, ttl: UInt8, tag: Data, body: Data) {
        self.kind = kind
        self.bodyType = bodyType
        self.ttl = ttl
        self.tag = tag
        self.body = body
    }

    public func encode() -> Data {
        var out = Data(capacity: Envelope.headerSize + body.count)
        out.append(Envelope.version)
        out.append(kind.rawValue)
        out.append(bodyType.rawValue)
        out.append(ttl)
        out.append(tag)
        out.append(body)
        return out
    }

    public static func decode(_ data: Data) -> Envelope? {
        let b = [UInt8](data)
        if b.count < headerSize { return nil }
        if b.count - headerSize > maxBodySize { return nil }
        if b[0] != version { return nil }
        guard let kind = EnvelopeKind(rawValue: b[1]), let bodyType = BodyType(rawValue: b[2]) else { return nil }
        let tag = Data(b[4..<12])
        let body = Data(b[headerSize...])
        return Envelope(kind: kind, bodyType: bodyType, ttl: b[3], tag: tag, body: body)
    }

    public func decremented() -> Envelope {
        return Envelope(kind: kind, bodyType: bodyType, ttl: ttl > 0 ? ttl - 1 : 0, tag: tag, body: body)
    }
}
