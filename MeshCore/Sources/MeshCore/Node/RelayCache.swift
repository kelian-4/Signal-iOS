import Foundation

public struct RelayEntry: Equatable {
    public let msgId: String

    public let envelope: Data
    public let insertedMs: Int64
    public var handoffs: Int
}

public final class RelayCache {
    public let maxEntries: Int
    public let maxBytes: Int
    public let ttlMs: Int64
    private var items: [String: RelayEntry] = [:]
    private var totalBytes = 0

    public init(maxEntries: Int = 200, maxBytes: Int = 512 * 1024, ttlMs: Int64 = 60 * 60 * 1000) {
        self.maxEntries = maxEntries
        self.maxBytes = maxBytes
        self.ttlMs = ttlMs
    }

    public var count: Int { return items.count }
    public var byteCount: Int { return totalBytes }

    public func contains(_ msgId: String) -> Bool {
        return items[msgId] != nil
    }

    @discardableResult
    public func insert(msgId: String, envelope: Data, nowMs: Int64) -> Bool {
        if items[msgId] != nil { return false }
        items[msgId] = RelayEntry(msgId: msgId, envelope: envelope, insertedMs: nowMs, handoffs: 0)
        totalBytes += envelope.count
        evictIfNeeded()
        return true
    }

    private func evictIfNeeded() {
        while items.count > maxEntries || totalBytes > maxBytes {
            guard let oldest = items.values.min(by: { $0.insertedMs < $1.insertedMs }) else { return }
            remove(oldest.msgId)
        }
    }

    public func remove(_ msgId: String) {
        if let e = items[msgId] {
            totalBytes -= e.envelope.count
            items[msgId] = nil
        }
    }

    public func noteHandoff(_ msgId: String) {
        if var e = items[msgId] {
            e.handoffs += 1
            items[msgId] = e
        }
    }

    public func gc(nowMs: Int64) {
        let expired = items.values.filter { nowMs - $0.insertedMs >= ttlMs }.map { $0.msgId }
        for id in expired { remove(id) }
    }

    public func entries() -> [RelayEntry] {
        return items.values.sorted { $0.insertedMs < $1.insertedMs }
    }

    public func hasEntriesToForward(maxHandoffs: Int) -> Bool {
        return items.values.contains { $0.handoffs < maxHandoffs }
    }
}
