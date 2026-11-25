import Foundation

public enum Proto {
    public static let version: UInt8 = 1
    public static let typeText: UInt8 = 0x01
    public static let typeAck: UInt8 = 0x02
    public static let headerSize = 14
    public static let msgIdSize = 8
    public static let partialTTLms: Int64 = 5 * 60 * 1000
    public static let dedupTTLms: Int64 = 60 * 60 * 1000
    public static let maxFragments = 65535
}

public enum ProtocolError: Error {
    case frameSizeTooSmall
    case payloadTooLarge
}

public struct Frame: Equatable {
    public let type: UInt8
    public let msgId: Data
    public let fragIndex: Int
    public let fragTotal: Int
    public let payload: Data

    public init(type: UInt8, msgId: Data, fragIndex: Int, fragTotal: Int, payload: Data) {
        self.type = type
        self.msgId = msgId
        self.fragIndex = fragIndex
        self.fragTotal = fragTotal
        self.payload = payload
    }

    public func encode() -> Data {
        var out = Data(capacity: Proto.headerSize + payload.count)
        out.append(Proto.version)
        out.append(type)
        out.append(msgId)
        out.append(UInt8((fragIndex >> 8) & 0xFF))
        out.append(UInt8(fragIndex & 0xFF))
        out.append(UInt8((fragTotal >> 8) & 0xFF))
        out.append(UInt8(fragTotal & 0xFF))
        out.append(payload)
        return out
    }

    public static func decode(_ data: Data) -> Frame? {
        let b = [UInt8](data)
        if b.count < Proto.headerSize { return nil }
        let version = b[0]
        let type = b[1]
        if version != Proto.version { return nil }
        if type != Proto.typeText && type != Proto.typeAck { return nil }
        let idx = (Int(b[10]) << 8) | Int(b[11])
        let total = (Int(b[12]) << 8) | Int(b[13])
        if total == 0 || idx >= total { return nil }
        let payload = Data(b[Proto.headerSize...])
        if type == Proto.typeAck && (idx != 0 || total != 1 || !payload.isEmpty) { return nil }
        return Frame(type: type, msgId: Data(b[2..<10]), fragIndex: idx, fragTotal: total, payload: payload)
    }

    public static func ack(msgId: Data) -> Frame {
        return Frame(type: Proto.typeAck, msgId: msgId, fragIndex: 0, fragTotal: 1, payload: Data())
    }
}

public func fragment(payload: Data, maxFrameSize: Int, msgId: Data, type: UInt8 = Proto.typeText) throws -> [Frame] {
    let chunk = maxFrameSize - Proto.headerSize
    guard chunk >= 1 else { throw ProtocolError.frameSizeTooSmall }
    let bytes = [UInt8](payload)
    let total = max(1, (bytes.count + chunk - 1) / chunk)
    guard total <= Proto.maxFragments else { throw ProtocolError.payloadTooLarge }
    var frames = [Frame]()
    frames.reserveCapacity(total)
    for i in 0..<total {
        let from = i * chunk
        let to = min(bytes.count, from + chunk)
        let part = from < to ? Data(bytes[from..<to]) : Data()
        frames.append(Frame(type: type, msgId: msgId, fragIndex: i, fragTotal: total, payload: part))
    }
    return frames
}
