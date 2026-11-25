import Foundation

public enum OutboxState: String, Codable {

    case queued

    case sent

    case delivered
    case expired
}

public struct OutboxEntry: Codable, Equatable {
    public var msgId: String

    public var envelope: Data
    public var createdMs: Int64
    public var state: OutboxState
    public var sentMs: Int64?
    public var deliveredMs: Int64?
    public var attempts: Int

    public init(msgId: String, envelope: Data, createdMs: Int64) {
        self.msgId = msgId
        self.envelope = envelope
        self.createdMs = createdMs
        self.state = .queued
        self.sentMs = nil
        self.deliveredMs = nil
        self.attempts = 0
    }
}

public final class Outbox {
    private let store: DocumentStore
    private let name: String
    private var items: [String: OutboxEntry] = [:]
    private let lock = NSLock()

    public init(store: DocumentStore, name: String = "outbox") {
        self.store = store
        self.name = name
        if let list = Documents.read([OutboxEntry].self, from: store, name: name) {
            for e in list { items[e.msgId] = e }
        }
    }

    private func persist() {
        let list = items.values.sorted { $0.createdMs < $1.createdMs }
        Documents.write(list, to: store, name: name)
    }

    public func entries() -> [OutboxEntry] {
        lock.lock()
        defer { lock.unlock() }
        return items.values.sorted { $0.createdMs < $1.createdMs }
    }

    public func pending() -> [OutboxEntry] {
        return entries().filter { $0.state == .queued || $0.state == .sent }
    }

    public func entry(_ msgId: String) -> OutboxEntry? {
        lock.lock()
        defer { lock.unlock() }
        return items[msgId]
    }

    public func contains(_ msgId: String) -> Bool {
        return entry(msgId) != nil
    }

    public func add(_ entry: OutboxEntry) {
        lock.lock()
        defer { lock.unlock() }
        items[entry.msgId] = entry
        persist()
    }

    public func noteAttempt(_ msgId: String) {
        lock.lock()
        defer { lock.unlock() }
        guard var e = items[msgId] else { return }
        e.attempts += 1
        items[msgId] = e
        persist()
    }

    @discardableResult
    public func markSent(_ msgId: String, nowMs: Int64) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard var e = items[msgId], e.state == .queued else { return false }
        e.state = .sent
        e.sentMs = nowMs
        items[msgId] = e
        persist()
        return true
    }

    @discardableResult
    public func markDelivered(_ msgId: String, nowMs: Int64) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard var e = items[msgId], e.state != .delivered else { return false }
        e.state = .delivered
        e.deliveredMs = nowMs
        items[msgId] = e
        persist()
        return true
    }

    @discardableResult
    public func expire(olderThanMs cutoff: Int64) -> [String] {
        lock.lock()
        defer { lock.unlock() }
        var ids = [String]()
        for (id, e) in items where (e.state == .queued || e.state == .sent) && e.createdMs < cutoff {
            var copy = e
            copy.state = .expired
            items[id] = copy
            ids.append(id)
        }
        if !ids.isEmpty { persist() }
        return ids
    }

    public func remove(_ msgId: String) {
        lock.lock()
        defer { lock.unlock() }
        items[msgId] = nil
        persist()
    }
}
