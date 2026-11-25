import Foundation
import MeshCore
#if canImport(os)
import os
#endif

public final class FieldJournal: MeshLogger {
    private let url: URL
    private let maxBytes: Int
    private let lock = NSLock()
    private let formatter: DateFormatter
    #if canImport(os)
    private let osLog = Logger(subsystem: "cm.messagerie.mesh", category: "field")
    #endif

    public init(directory: URL, fileName: String = "mesh-journal.log", maxBytes: Int = 1_000_000) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.url = directory.appendingPathComponent(fileName)
        self.maxBytes = maxBytes
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        self.formatter = f
    }

    public var fileURL: URL { return url }

    public func log(_ event: String, _ fields: [String: String]) {
        let line = formatter.string(from: Date()) + " " + event + " "
            + fields.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }.joined(separator: " ") + "\n"
        #if canImport(os)
        osLog.info("\(line, privacy: .public)")
        #endif
        lock.lock()
        defer { lock.unlock() }
        guard let data = line.data(using: .utf8) else { return }
        if let existing = try? Data(contentsOf: url), existing.count + data.count > maxBytes {

            let keep = existing.suffix(maxBytes / 2)
            var trimmed = Data(keep)
            if let nl = trimmed.firstIndex(of: 0x0A) { trimmed = Data(trimmed[(nl + 1)...]) }
            try? trimmed.write(to: url, options: .atomic)
        }
        if FileManager.default.fileExists(atPath: url.path), let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile()
            h.write(data)
            try? h.close()
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        try? FileManager.default.removeItem(at: url)
    }
}
