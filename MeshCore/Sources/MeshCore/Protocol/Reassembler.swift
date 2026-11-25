import Foundation

public enum RxResult: Equatable {
    case partial
    case invalid
    case complete(msgId: Data, payload: Data)

    case duplicate(msgId: Data)
    case ack(msgId: Data)
}

public final class Reassembler {
    private final class Entry {
        let firstSeenMs: Int64
        let total: Int
        var frags: [Int: Data] = [:]
        init(firstSeenMs: Int64, total: Int) {
            self.firstSeenMs = firstSeenMs
            self.total = total
        }
    }

    private var partial: [String: Entry] = [:]
    private var completed: [String: Int64] = [:]

    public init() {}

    public func accept(_ data: Data, nowMs: Int64) -> RxResult {
        partial = partial.filter { nowMs - $0.value.firstSeenMs < Proto.partialTTLms }
        completed = completed.filter { nowMs - $0.value < Proto.dedupTTLms }
        guard let f = Frame.decode(data) else { return .invalid }
        if f.type == Proto.typeAck { return .ack(msgId: f.msgId) }
        let key = f.msgId.toHex()
        if completed[key] != nil { return .duplicate(msgId: f.msgId) }
        let entry: Entry
        if let existing = partial[key] {
            if existing.total != f.fragTotal { return .invalid }
            entry = existing
        } else {
            entry = Entry(firstSeenMs: nowMs, total: f.fragTotal)
            partial[key] = entry
        }
        if entry.frags[f.fragIndex] == nil { entry.frags[f.fragIndex] = f.payload }
        if entry.frags.count == entry.total {
            var out = Data()
            for i in 0..<entry.total {
                if let part = entry.frags[i] { out.append(part) }
            }
            partial[key] = nil
            completed[key] = nowMs
            return .complete(msgId: f.msgId, payload: out)
        }
        return .partial
    }

    public func hasCompleted(msgIdHex: String) -> Bool {
        return completed[msgIdHex] != nil
    }
}
