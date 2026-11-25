import Foundation
import SwiftUI
import UserNotifications
import MeshCore
import MeshBLE

struct ContactRow: Identifiable, Equatable {
    let id: String
    let name: String
    let trust: TrustLevel
    let status: ContactStatus
    let keyChange: Bool
    let blocked: Bool
    let preview: String
    let lastMs: Int64
    let requestText: String?
}

struct Bubble: Identifiable, Equatable {
    let id: String
    let text: String
    let outgoing: Bool
    let state: MessageState
    let timestampMs: Int64
}

final class AppModel: NSObject, ObservableObject, MeshServiceDelegate {
    static let shared = AppModel()

    @Published var hasIdentity = false
    @Published var displayName = ""
    @Published var rows: [ContactRow] = []
    @Published var status = BLEStatus()
    @Published var alert: String?
    @Published var recoveryWords: [String]?
    @Published var qrText = ""
    @Published var revision = 0

    let transport: MeshBLETransport
    let journal: FieldJournal
    private(set) var service: MeshService!
    private let queue: DispatchQueue

    override init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Messagerie", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        let t = MeshBLETransport()
        transport = t
        journal = FieldJournal(directory: support)
        queue = t.queue
        super.init()
        transport.logger = journal
        service = MeshService(directory: support.appendingPathComponent("data", isDirectory: true),
                              vault: KeychainVault(), transport: transport)
        service.logger = journal
        service.delegate = self
        transport.hasPendingWork = { [weak self] in self?.service.node?.hasPendingWork ?? false }
        transport.onTick = { [weak self] in self?.service.tick() }
        transport.onStatus = { [weak self] st in self?.status = st }
        queue.async { self.refresh() }
        transport.start()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func run(_ work: @escaping () -> Void) {
        queue.async(execute: work)
    }

    func refresh() {
        let has = service.hasIdentity
        let name = service.displayName
        var rows: [ContactRow] = []
        var qr = ""
        if let m = service.messenger {
            qr = m.myQR()
            for c in m.contacts.all() {
                let msgs = m.messages.messages(with: c.id)
                rows.append(ContactRow(id: c.id, name: c.displayName, trust: c.trust, status: c.status,
                                       keyChange: c.hasKeyChangeAlert, blocked: c.blocked,
                                       preview: msgs.last?.text ?? "", lastMs: msgs.last?.timestampMs ?? c.addedMs,
                                       requestText: c.requestText))
            }
            rows.sort { $0.lastMs > $1.lastMs }
        }
        DispatchQueue.main.async {
            self.hasIdentity = has
            self.displayName = name
            self.rows = rows
            self.qrText = qr
            self.revision += 1
        }
    }

    func bubbles(for contactId: String) -> [Bubble] {
        guard let m = service.messenger else { return [] }
        return m.messages.messages(with: contactId).map {
            Bubble(id: $0.id, text: $0.text, outgoing: $0.outgoing, state: $0.state, timestampMs: $0.timestampMs)
        }
    }

    func fetchBubbles(for contactId: String, completion: @escaping ([Bubble]) -> Void) {
        queue.async {
            let list = self.bubbles(for: contactId)
            DispatchQueue.main.async { completion(list) }
        }
    }

    func securityCode(for contactId: String, completion: @escaping (String?) -> Void) {
        queue.async {
            var code: String?
            if let m = self.service.messenger, let c = m.contacts.contact(id: contactId) {
                code = SecurityCode.make(localKey: m.crypto.publicKey, remoteKey: c.identityKey)
            }
            DispatchQueue.main.async { completion(code) }
        }
    }

    func createIdentity(name: String) {
        queue.async {
            do {
                let words = try self.service.createIdentity(displayName: name)
                DispatchQueue.main.async { self.recoveryWords = words }
            } catch {
                self.fail("Impossible de créer l'identité.")
            }
            self.refresh()
            self.transport.connectNow()
        }
    }

    func restoreIdentity(phrase: String, name: String) {
        queue.async {
            do {
                try self.service.restoreIdentity(words: Bip39.normalize(phrase), displayName: name)
            } catch {
                self.fail("Phrase de récupération invalide.")
            }
            self.refresh()
        }
    }

    func addContact(qr: String, firstText: String) {
        queue.async {
            do {
                switch try self.service.messenger!.addContact(fromQR: qr, firstText: firstText) {
                case .requestSent:
                    self.fail("Demande envoyée. Elle partira dès qu'un appareil proche sera joignable.")
                case .keyChangeAlert:
                    self.fail("La clé de ce contact a changé. Vérifiez-le en personne.")
                }
            } catch MessengerError.invalidOrExpiredQR {
                self.fail("Code invalide ou expiré. Demandez à votre contact d'afficher un code récent.")
            } catch MessengerError.ownKey {
                self.fail("C'est votre propre code.")
            } catch MessengerError.dailyLimitReached {
                self.fail("Limite quotidienne de nouveaux contacts atteinte.")
            } catch {
                self.fail("Impossible d'ajouter ce contact.")
            }
            self.refresh()
            self.transport.connectNow()
        }
    }

    func accept(_ id: String) {
        queue.async {
            try? self.service.messenger?.acceptRequest(contactId: id)
            self.refresh()
            self.transport.connectNow()
        }
    }

    func reject(_ id: String, block: Bool) {
        queue.async {
            self.service.messenger?.rejectRequest(contactId: id, block: block)
            self.refresh()
        }
    }

    func report(_ id: String) {
        queue.async {
            if let m = self.service.messenger, let c = m.contacts.contact(id: id) {
                m.abuse.report(key: c.identityKey, reason: "signalement manuel", nowMs: systemNowMs())
            }
            self.fail("Signalement enregistré localement sur cet appareil.")
        }
    }

    func setBlocked(_ id: String, _ blocked: Bool) {
        queue.async {
            guard let m = self.service.messenger, let c = m.contacts.contact(id: id) else { return }
            m.contacts.setBlocked(id: id, blocked)
            if blocked { m.abuse.block(key: c.identityKey) } else { m.abuse.unblock(key: c.identityKey) }
            self.refresh()
        }
    }

    func resolveKeyChange(_ id: String, accept: Bool) {
        queue.async {
            self.service.messenger?.resolveKeyChange(contactId: id, accept: accept)
            self.refresh()
        }
    }

    func send(_ text: String, to id: String) {
        queue.async {
            do {
                _ = try self.service.messenger?.sendText(to: id, text: text)
            } catch MessengerError.textTooLong {
                self.fail("Message trop long.")
            } catch MessengerError.blocked {
                self.fail("Contact bloqué.")
            } catch {
                self.fail("Message non envoyé.")
            }
            self.refresh()
            self.transport.connectNow()
        }
    }

    func rename(_ name: String) {
        queue.async {
            try? self.service.rename(to: name)
            self.refresh()
        }
    }

    func exportBackup(completion: @escaping (URL?) -> Void) {
        queue.async {
            var url: URL?
            if let data = try? self.service.exportBackup() {
                let target = FileManager.default.temporaryDirectory.appendingPathComponent("messagerie-sauvegarde.mshb")
                try? data.write(to: target, options: .atomic)
                url = target
            }
            DispatchQueue.main.async { completion(url) }
        }
    }

    func importBackup(from url: URL) {
        queue.async {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                try self.service.importBackup(data)
                self.fail("Sauvegarde importée. Les sessions seront renégociées au prochain message.")
            } catch {
                self.fail("Sauvegarde illisible ou phrase de récupération différente.")
            }
            self.refresh()
        }
    }

    func showWords() {
        queue.async {
            let words = self.service.recoveryWords()
            DispatchQueue.main.async { self.recoveryWords = words }
        }
    }

    func wipe() {
        queue.async {
            self.service.wipeEverything()
            self.journal.clear()
            self.refresh()
        }
    }

    private func fail(_ text: String) {
        DispatchQueue.main.async { self.alert = text }
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let req = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    func serviceDidChange(_ service: MeshService) { refresh() }

    func service(_ service: MeshService, didReceive message: ChatMessage, from contact: Contact) {
        notify(title: contact.displayName, body: message.text)
    }

    func service(_ service: MeshService, contactRequestFrom contact: Contact) {
        notify(title: "Nouvelle demande de contact", body: contact.displayName)
    }

    func service(_ service: MeshService, keyChangedFor contact: Contact) {
        notify(title: "Clé de sécurité modifiée", body: contact.displayName)
    }
}
