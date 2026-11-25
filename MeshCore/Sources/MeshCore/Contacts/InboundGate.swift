import Foundation

public enum GateDecision: Equatable {
    case accept
    case rejectBlocked

    case rejectRequestLimit
    case rejectLink
    case rejectTooLong
}

public struct StrangerRecord: Codable, Equatable {
    public var requests: Int
    public var firstSeenMs: Int64
}

public final class AbuseGuard {
    public static let maxRequestTextBytes = 512

    public static let maxRequestsPerStranger = 1
    public static let maxOutgoingStrangersPerDay = 5

    private struct State: Codable {
        var strangers: [String: StrangerRecord] = [:]
        var outgoingDay: Int64 = 0
        var outgoingCount: Int = 0
        var blockedKeys: [String] = []
        var reports: [LocalReport] = []
    }

    private let store: DocumentStore
    private let name: String
    private var state: State

    public init(store: DocumentStore, name: String = "abuse") {
        self.store = store
        self.name = name
        self.state = Documents.read(State.self, from: store, name: name) ?? State()
    }

    private func persist() {
        Documents.write(state, to: store, name: name)
    }

    public static func containsLink(_ text: String) -> Bool {
        let lower = text.lowercased()
        for marker in ["http://", "https://", "www.", "ftp://", "://", "t.me/", "wa.me/", "bit.ly/"] {
            if lower.contains(marker) { return true }
        }

        let tlds = ["com", "net", "org", "io", "cm", "info", "xyz", "me", "co", "app", "link", "ly"]
        for word in lower.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" }) {
            let parts = word.split(separator: ".")
            if parts.count >= 2, let last = parts.last {
                let cleaned = String(last.prefix(while: { $0.isLetter }))
                if tlds.contains(cleaned) && parts[parts.count - 2].count >= 2 { return true }
            }
        }
        return false
    }

    public func evaluateRequest(senderKey: Data, text: String, nowMs: Int64) -> GateDecision {
        let hex = senderKey.toHex()
        if state.blockedKeys.contains(hex) { return .rejectBlocked }
        if (state.strangers[hex]?.requests ?? 0) >= AbuseGuard.maxRequestsPerStranger { return .rejectRequestLimit }
        if text.utf8.count > AbuseGuard.maxRequestTextBytes { return .rejectTooLong }
        if AbuseGuard.containsLink(text) { return .rejectLink }
        return .accept
    }

    public func recordRequest(senderKey: Data, nowMs: Int64) {
        let hex = senderKey.toHex()
        var rec = state.strangers[hex] ?? StrangerRecord(requests: 0, firstSeenMs: nowMs)
        rec.requests += 1
        state.strangers[hex] = rec
        persist()
    }

    public func evaluateStrangerText(senderKey: Data) -> GateDecision {
        let hex = senderKey.toHex()
        if state.blockedKeys.contains(hex) { return .rejectBlocked }
        return .rejectRequestLimit
    }

    private func day(_ nowMs: Int64) -> Int64 { return nowMs / 86_400_000 }

    public func outgoingStrangersToday(nowMs: Int64) -> Int {
        return state.outgoingDay == day(nowMs) ? state.outgoingCount : 0
    }

    public func canContactNewStranger(nowMs: Int64) -> Bool {
        return outgoingStrangersToday(nowMs: nowMs) < AbuseGuard.maxOutgoingStrangersPerDay
    }

    public func recordOutgoingStranger(nowMs: Int64) {
        if state.outgoingDay != day(nowMs) {
            state.outgoingDay = day(nowMs)
            state.outgoingCount = 0
        }
        state.outgoingCount += 1
        persist()
    }

    public func block(key: Data) {
        let hex = key.toHex()
        if !state.blockedKeys.contains(hex) { state.blockedKeys.append(hex) }
        persist()
    }

    public func unblock(key: Data) {
        state.blockedKeys.removeAll { $0 == key.toHex() }
        persist()
    }

    public func isBlocked(key: Data) -> Bool {
        return state.blockedKeys.contains(key.toHex())
    }

    public func report(key: Data, reason: String, nowMs: Int64) {
        state.reports.append(LocalReport(keyHex: key.toHex(), reason: reason, atMs: nowMs))
        persist()
    }

    public func reports() -> [LocalReport] { return state.reports }
}

public struct LocalReport: Codable, Equatable {
    public let keyHex: String
    public let reason: String
    public let atMs: Int64
}
