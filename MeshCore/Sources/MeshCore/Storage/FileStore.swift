import Foundation

public protocol DocumentStore: AnyObject {
    func load(_ name: String) -> Data?
    func save(_ name: String, data: Data)
    func remove(_ name: String)
}

public final class FileDocumentStore: DocumentStore {
    private let directory: URL
    private let lock = NSLock()

    public init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func url(_ name: String) -> URL {
        return directory.appendingPathComponent(name + ".json")
    }

    public func load(_ name: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return try? Data(contentsOf: url(name))
    }

    public func save(_ name: String, data: Data) {
        lock.lock()
        defer { lock.unlock() }
        #if os(iOS)
        let options: Data.WritingOptions = [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
        #else
        let options: Data.WritingOptions = [.atomic]
        #endif
        try? data.write(to: url(name), options: options)
    }

    public func remove(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        try? FileManager.default.removeItem(at: url(name))
    }
}

public final class MemoryDocumentStore: DocumentStore {
    private var docs: [String: Data] = [:]
    private let lock = NSLock()

    public init() {}

    public func load(_ name: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return docs[name]
    }

    public func save(_ name: String, data: Data) {
        lock.lock()
        defer { lock.unlock() }
        docs[name] = data
    }

    public func remove(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        docs[name] = nil
    }
}

public enum Documents {
    public static func read<T: Decodable>(_ type: T.Type, from store: DocumentStore, name: String) -> T? {
        guard let data = store.load(name) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    public static func write<T: Encodable>(_ value: T, to store: DocumentStore, name: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if let data = try? encoder.encode(value) {
            store.save(name, data: data)
        }
    }
}
