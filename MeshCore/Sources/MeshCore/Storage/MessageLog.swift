import Foundation

public enum MessageState: String, Codable {

    case waitingSession
    case queued

    case sent

    case delivered
    case received
    case failed
}

public struct ChatMessage: Codable, Equatable {
    public var id: String
    public var contactId: String
    public var outgoing: Bool
    public var text: String
    public var timestampMs: Int64
    public var state: MessageState
    public var outboxId: String?
}

public final class MessageLog {
    private let store: DocumentStore
    private let name: String
    private var items: [ChatMessage] = []

    public init(store: DocumentStore, name: String = "messages") {
        self.store = store
        self.name = name
        self.items = Documents.read([ChatMessage].self, from: store, name: name) ?? []
    }

    private func persist() { Documents.write(items, to: store, name: name) }

    public func all() -> [ChatMessage] { return items }

    public func messages(with contactId: String) -> [ChatMessage] {
        return items.filter { $0.contactId == contactId }.sorted { $0.timestampMs < $1.timestampMs }
    }

    public func add(_ m: ChatMessage) {
        items.append(m)
        persist()
    }

    public func update(id: String, _ change: (inout ChatMessage) -> Void) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        change(&items[i])
        persist()
    }

    public func message(outboxId: String) -> ChatMessage? {
        return items.first { $0.outboxId == outboxId }
    }

    public func waiting(for contactId: String) -> [ChatMessage] {
        return items.filter { $0.contactId == contactId && $0.state == .waitingSession }
            .sorted { $0.timestampMs < $1.timestampMs }
    }

    public func replaceAll(_ list: [ChatMessage]) {
        items = list
        persist()
    }

    public func exportData() -> Data {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        return (try? enc.encode(items)) ?? Data("[]".utf8)
    }

    public static func decode(_ data: Data) -> [ChatMessage] {
        return (try? JSONDecoder().decode([ChatMessage].self, from: data)) ?? []
    }
}
