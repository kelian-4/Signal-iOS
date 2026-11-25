import Foundation
import CryptoKit

public enum TrustLevel: String, Codable {

    case unverified

    case verified
}

public enum ContactStatus: String, Codable {

    case pendingIncoming

    case pendingOutgoing
    case accepted
}

public struct Contact: Codable, Equatable {
    public var id: String
    public var identityKey: Data
    public var displayName: String
    public var trust: TrustLevel
    public var status: ContactStatus
    public var addedMs: Int64
    public var verifiedMs: Int64?
    public var blocked: Bool

    public var keyChangeCandidate: Data?
    public var keyChangeMs: Int64?

    public var routingSecret: Data?

    public var requestText: String?

    public var hasKeyChangeAlert: Bool { return keyChangeCandidate != nil }
}

public enum KeyEvaluation: Equatable {
    case known(contactId: String)
    case newIdentity

    case keyChanged(contactId: String)
}

public final class ContactBook {
    private let store: DocumentStore
    private let name: String
    private var contacts: [String: Contact] = [:]

    public init(store: DocumentStore, name: String = "contacts") {
        self.store = store
        self.name = name
        if let list = Documents.read([Contact].self, from: store, name: name) {
            for c in list { contacts[c.id] = c }
        }
    }

    private func persist() {
        Documents.write(all(), to: store, name: name)
    }

    public func all() -> [Contact] {
        return contacts.values.sorted { $0.addedMs < $1.addedMs }
    }

    public func contact(id: String) -> Contact? { return contacts[id] }

    public func contact(withKey key: Data) -> Contact? {
        return contacts.values.first { $0.identityKey == key }
    }

    public static func makeId(forKey key: Data) -> String {
        return Data(SHA256.hash(data: key)).prefix(8).toHex()
    }

    public func evaluate(key: Data, displayName: String) -> KeyEvaluation {
        if let c = contact(withKey: key) { return .known(contactId: c.id) }
        let lower = displayName.lowercased()
        if let c = contacts.values.first(where: { $0.displayName.lowercased() == lower && $0.status == .accepted }) {
            return .keyChanged(contactId: c.id)
        }
        return .newIdentity
    }

    @discardableResult
    public func add(key: Data, displayName: String, status: ContactStatus, nowMs: Int64,
                    routingSecret: Data?, requestText: String? = nil) -> Contact {
        if var existing = contact(withKey: key) {
            existing.displayName = displayName
            if existing.status != .accepted { existing.status = status }
            if existing.routingSecret == nil { existing.routingSecret = routingSecret }
            contacts[existing.id] = existing
            persist()
            return existing
        }
        let c = Contact(id: ContactBook.makeId(forKey: key), identityKey: key, displayName: displayName,
                        trust: .unverified, status: status, addedMs: nowMs, verifiedMs: nil, blocked: false,
                        keyChangeCandidate: nil, keyChangeMs: nil, routingSecret: routingSecret, requestText: requestText)
        contacts[c.id] = c
        persist()
        return c
    }

    public func setStatus(id: String, _ status: ContactStatus) {
        guard var c = contacts[id] else { return }
        c.status = status
        contacts[id] = c
        persist()
    }

    public func setRoutingSecret(id: String, _ secret: Data) {
        guard var c = contacts[id], c.routingSecret == nil else { return }
        c.routingSecret = secret
        contacts[id] = c
        persist()
    }

    public func setBlocked(id: String, _ blocked: Bool) {
        guard var c = contacts[id] else { return }
        c.blocked = blocked
        contacts[id] = c
        persist()
    }

    public func rename(id: String, to newName: String) {
        guard var c = contacts[id] else { return }
        c.displayName = newName
        contacts[id] = c
        persist()
    }

    public func markVerified(id: String, nowMs: Int64) {
        guard var c = contacts[id] else { return }
        c.trust = .verified
        c.verifiedMs = nowMs
        contacts[id] = c
        persist()
    }

    public func raiseKeyChange(id: String, newKey: Data, nowMs: Int64) {
        guard var c = contacts[id], c.identityKey != newKey else { return }
        c.trust = .unverified
        c.verifiedMs = nil
        c.keyChangeCandidate = newKey
        c.keyChangeMs = nowMs
        contacts[id] = c
        persist()
    }

    public func dismissKeyChange(id: String) {
        guard var c = contacts[id] else { return }
        c.keyChangeCandidate = nil
        c.keyChangeMs = nil
        contacts[id] = c
        persist()
    }

    public func acceptKeyChange(id: String, routingSecret: Data?) {
        guard var c = contacts[id], let newKey = c.keyChangeCandidate else { return }
        c.identityKey = newKey
        c.trust = .unverified
        c.verifiedMs = nil
        c.keyChangeCandidate = nil
        c.keyChangeMs = nil
        c.routingSecret = routingSecret
        contacts[id] = c
        persist()
    }

    public func remove(id: String) {
        contacts[id] = nil
        persist()
    }

    public func replaceAll(_ list: [Contact]) {
        contacts = [:]
        for c in list { contacts[c.id] = c }
        persist()
    }
}
