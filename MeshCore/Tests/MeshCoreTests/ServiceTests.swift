import XCTest
import CryptoKit
@testable import MeshCore

final class ServiceTests: XCTestCase {
    private func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private final class Recorder: MeshServiceDelegate {
        var received: [ChatMessage] = []
        var requests: [Contact] = []
        var keyChanges: [Contact] = []
        func serviceDidChange(_ service: MeshService) {}
        func service(_ service: MeshService, didReceive message: ChatMessage, from contact: Contact) { received.append(message) }
        func service(_ service: MeshService, contactRequestFrom contact: Contact) { requests.append(contact) }
        func service(_ service: MeshService, keyChangedFor contact: Contact) { keyChanges.append(contact) }
    }

    private func makeService(vault: SeedVault = MemorySeedVault(), dir: URL? = nil, clock: TestClock) -> (MeshService, SimTransport, Recorder) {
        let t = SimTransport(name: "t\(UUID().uuidString.prefix(4))")
        let s = MeshService(directory: dir ?? tempDir(), vault: vault, transport: t, now: clock.now)
        let r = Recorder()
        s.delegate = r
        return (s, t, r)
    }

    func testCreateIdentityGivesTwentyFourWordsAndPersists() throws {
        let clock = TestClock(), vault = MemorySeedVault(), dir = tempDir()
        let (s, _, _) = makeService(vault: vault, dir: dir, clock: clock)
        XCTAssertFalse(s.hasIdentity)
        let words = try s.createIdentity(displayName: "Alice")
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(s.recoveryWords(), words)
        let key = s.publicKey

        let (again, _, _) = makeService(vault: vault, dir: dir, clock: clock)
        XCTAssertTrue(again.hasIdentity)
        XCTAssertEqual(again.publicKey, key)
        XCTAssertEqual(again.displayName, "Alice")
    }

    func testRestoreFromPhraseGivesSameIdentity() throws {
        let clock = TestClock()
        let (a, _, _) = makeService(clock: clock)
        let words = try a.createIdentity(displayName: "Alice")
        let (b, _, _) = makeService(clock: clock)
        try b.restoreIdentity(words: words, displayName: "Alice")
        XCTAssertEqual(a.publicKey, b.publicKey)
    }

    func testEmptyNameRejectedAndNameClamped() throws {
        let clock = TestClock()
        let (s, _, _) = makeService(clock: clock)
        XCTAssertThrowsError(try s.createIdentity(displayName: "   "))
        _ = try s.createIdentity(displayName: String(repeating: "x", count: 80))
        XCTAssertEqual(s.displayName.count, MeshService.maxNameLength)
    }

    func testEndToEndWithProductionCryptoAndBackupRestore() throws {
        let clock = TestClock(), net = SimNetwork()
        let (alice, ta, _) = makeService(clock: clock)
        let (bob, tb, bobRec) = makeService(clock: clock)
        _ = try alice.createIdentity(displayName: "Alice")
        _ = try bob.createIdentity(displayName: "Bob")
        net.connect(ta, tb)

        try alice.messenger!.addContact(fromQR: bob.messenger!.myQR(), firstText: "salut")
        net.pump()
        XCTAssertEqual(bobRec.requests.count, 1)
        try bob.messenger!.acceptRequest(contactId: bobRec.requests[0].id)
        net.pump()
        let bobId = alice.messenger!.contacts.all().first { $0.displayName == "Bob" }!.id
        _ = try alice.messenger!.sendText(to: bobId, text: "bonjour")
        net.pump()
        XCTAssertEqual(bobRec.received.map { $0.text }, ["bonjour"])
        XCTAssertEqual(alice.messenger!.messages.messages(with: bobId).last?.state, .delivered)

        let words = alice.recoveryWords()!
        let file = try alice.exportBackup()
        let (alice2, ta2, _) = makeService(clock: clock)
        try alice2.restoreIdentity(words: words, displayName: nil)
        try alice2.importBackup(file)
        XCTAssertEqual(alice2.publicKey, alice.publicKey)
        XCTAssertEqual(alice2.displayName, "Alice")
        XCTAssertEqual(alice2.messenger!.messages.all().map { $0.text }, alice.messenger!.messages.all().map { $0.text })
        XCTAssertTrue(alice2.messenger!.messages.all().contains { $0.text == "bonjour" })
        XCTAssertFalse(alice2.messenger!.sessions.hasSession(contactId: bobId))

        let net2 = SimNetwork()
        net2.connect(ta2, tb)
        _ = try alice2.messenger!.sendText(to: bobId, text: "après restauration")
        net2.pump()
        XCTAssertEqual(bobRec.received.last?.text, "après restauration")
    }

    func testWrongBackupKeyRejected() throws {
        let clock = TestClock()
        let (a, _, _) = makeService(clock: clock)
        _ = try a.createIdentity(displayName: "A")
        let file = try a.exportBackup()
        let (b, _, _) = makeService(clock: clock)
        _ = try b.createIdentity(displayName: "B")
        XCTAssertThrowsError(try b.importBackup(file))
    }

    func testWipeRemovesIdentity() throws {
        let clock = TestClock(), vault = MemorySeedVault()
        let (s, _, _) = makeService(vault: vault, clock: clock)
        _ = try s.createIdentity(displayName: "A")
        s.wipeEverything()
        XCTAssertFalse(s.hasIdentity)
        XCTAssertNil(vault.loadEntropy())
    }

    func testSessionCryptoRoundTripAndTamper() throws {
        let a = try CryptoKitIdentity(entropy: Data(repeating: 1, count: 32))
        let b = try CryptoKitIdentity(entropy: Data(repeating: 2, count: 32))
        let sa = EphemeralSessionCrypto(identity: a, store: MemoryDocumentStore())
        let sb = EphemeralSessionCrypto(identity: b, store: MemoryDocumentStore())
        try sa.startSession(contactId: "b", remoteIdentity: b.publicKey, bundle: Data())
        var c = try sa.encrypt(Data("hello".utf8), for: "b")
        XCTAssertEqual(try sb.decrypt(c, from: "a", remoteIdentity: a.publicKey), Data("hello".utf8))
        XCTAssertTrue(sb.hasSession(contactId: "a"))
        c[c.count - 1] ^= 1
        XCTAssertThrowsError(try sb.decrypt(c, from: "a", remoteIdentity: a.publicKey))
        let mallory = try CryptoKitIdentity(entropy: Data(repeating: 3, count: 32))
        let good = try sa.encrypt(Data("x".utf8), for: "b")
        XCTAssertThrowsError(try sb.decrypt(good, from: "m", remoteIdentity: mallory.publicKey))
    }

    func testSignatureAndSharedSecretSymmetry() throws {
        let a = try CryptoKitIdentity(entropy: Data(repeating: 9, count: 32))
        let b = try CryptoKitIdentity(entropy: Data(repeating: 8, count: 32))
        XCTAssertEqual(a.sharedSecret(with: b.publicKey), b.sharedSecret(with: a.publicKey))
        let sig = a.sign(Data("m".utf8))
        XCTAssertTrue(b.verify(publicKey: a.publicKey, message: Data("m".utf8), signature: sig))
        XCTAssertFalse(b.verify(publicKey: a.publicKey, message: Data("n".utf8), signature: sig))
    }
}
