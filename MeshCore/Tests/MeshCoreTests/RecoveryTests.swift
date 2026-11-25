import XCTest
@testable import MeshCore

final class RecoveryTests: XCTestCase {

    func testOfficialVectorAllZeroEntropy() throws {
        let words = try Bip39.mnemonic(fromEntropy: Data(count: 32))
        XCTAssertEqual(words, Array(repeating: "abandon", count: 23) + ["art"])
    }

    func testOfficialVector7f() throws {
        let words = try Bip39.mnemonic(fromEntropy: Data(repeating: 0x7f, count: 32))
        XCTAssertEqual(words.count, 24)
        XCTAssertEqual(words.first, "legal")
        XCTAssertEqual(words.last, "title")
    }

    func testOfficialVectorFF() throws {
        let words = try Bip39.mnemonic(fromEntropy: Data(repeating: 0xff, count: 32))
        XCTAssertEqual(words, Array(repeating: "zoo", count: 23) + ["vote"])
    }

    func testTwelveWordVector() throws {
        let words = try Bip39.mnemonic(fromEntropy: Data(count: 16))
        XCTAssertEqual(words, Array(repeating: "abandon", count: 11) + ["about"])
    }

    func testPhraseRoundTrip() throws {
        for _ in 0..<50 {
            let entropy = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
            let words = try Bip39.mnemonic(fromEntropy: entropy)
            XCTAssertEqual(words.count, 24)
            XCTAssertEqual(try Bip39.entropy(fromMnemonic: words), entropy)
        }
    }

    func testPhraseTypedByUserIsNormalised() throws {
        let entropy = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let words = try Bip39.mnemonic(fromEntropy: entropy)
        let typed = "  " + words.map { $0.uppercased() }.joined(separator: "  \n ") + " "
        XCTAssertEqual(try Bip39.entropy(fromMnemonic: Bip39.normalize(typed)), entropy)
    }

    func testBadPhrasesAreRejected() throws {
        var words = try Bip39.mnemonic(fromEntropy: Data(repeating: 0x42, count: 32))
        XCTAssertThrowsError(try Bip39.entropy(fromMnemonic: Array(words.dropLast()))) {
            XCTAssertEqual($0 as? Bip39Error, .invalidWordCount)
        }
        var unknown = words; unknown[3] = "banane"
        XCTAssertThrowsError(try Bip39.entropy(fromMnemonic: unknown)) {
            XCTAssertEqual($0 as? Bip39Error, .unknownWord("banane"))
        }

        words.swapAt(0, 1)
        XCTAssertThrowsError(try Bip39.entropy(fromMnemonic: words)) {
            XCTAssertEqual($0 as? Bip39Error, .badChecksum)
        }
        XCTAssertThrowsError(try Bip39.mnemonic(fromEntropy: Data(count: 31)))
    }

    func testWordListHas2048UniqueWords() {
        XCTAssertEqual(Bip39Words.english.count, 2048)
        XCTAssertEqual(Set(Bip39Words.english).count, 2048)
        XCTAssertEqual(Bip39Words.english.first, "abandon")
        XCTAssertEqual(Bip39Words.english.last, "zoo")
    }

    func testBackupSealOpenRoundTrip() throws {
        let entropy = Data(repeating: 7, count: 32)
        let payload = BackupPayload(displayName: "Alice", contacts: [], messages: Data("[]".utf8), createdMs: 42)
        let file = try RecoveryBackup.seal(try payload.encode(), entropy: entropy)
        XCTAssertNil(file.range(of: Data("Alice".utf8)), "the file is encrypted")
        XCTAssertEqual(try BackupPayload.decode(try RecoveryBackup.open(file, entropy: entropy)), payload)
    }

    func testBackupWithWrongPhraseOrCorruptionFails() throws {
        let file = try RecoveryBackup.seal(Data("secret".utf8), entropy: Data(repeating: 1, count: 32))
        XCTAssertThrowsError(try RecoveryBackup.open(file, entropy: Data(repeating: 2, count: 32))) {
            XCTAssertEqual($0 as? BackupError, .wrongPhraseOrCorrupted)
        }
        var corrupted = file
        corrupted[corrupted.count - 1] ^= 0x01
        XCTAssertThrowsError(try RecoveryBackup.open(corrupted, entropy: Data(repeating: 1, count: 32))) {
            XCTAssertEqual($0 as? BackupError, .wrongPhraseOrCorrupted)
        }
        XCTAssertThrowsError(try RecoveryBackup.open(Data("not a backup".utf8), entropy: Data(repeating: 1, count: 32))) {
            XCTAssertEqual($0 as? BackupError, .badFormat)
        }
    }

    func testRestoreFromPhraseAndBackupThenRenegotiateSessions() throws {
        let clock = TestClock(), net = SimNetwork()

        let entropy = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        let phrase = try Bip39.mnemonic(fromEntropy: entropy)
        let alice = Device(name: "alice", clock: clock, seed: entropy)
        let bob = Device(name: "bob", clock: clock)
        net.connect(alice.transport, bob.transport)
        try alice.messenger.addContact(fromQR: bob.messenger.myQR())
        net.pump()
        try bob.messenger.acceptRequest(contactId: bob.requests.first!.id)
        net.pump()
        let bobId = alice.contact(named: "bob")!.id
        _ = try alice.messenger.sendText(to: bobId, text: "avant la perte")
        net.pump()
        XCTAssertEqual(bob.received.count, 1)

        let payload = BackupPayload(displayName: "alice", contacts: alice.messenger.contacts.all(),
                                    messages: alice.messenger.messages.exportData(), createdMs: clock.ms)
        let file = try RecoveryBackup.seal(try payload.encode(), entropy: entropy)

        let restoredEntropy = try Bip39.entropy(fromMnemonic: Bip39.normalize(phrase.joined(separator: " ")))
        let restored = try BackupPayload.decode(try RecoveryBackup.open(file, entropy: restoredEntropy))
        let store2 = MemoryDocumentStore()
        ContactBook(store: store2).replaceAll(restored.contacts)
        MessageLog(store: store2).replaceAll(MessageLog.decode(restored.messages))
        let alice2 = Device(name: "alice2", clock: clock, seed: restoredEntropy, store: store2, displayName: "alice")

        XCTAssertEqual(alice2.crypto.publicKey, alice.crypto.publicKey, "same identity from the phrase")
        XCTAssertEqual(alice2.messenger.messages.all().map { $0.text }, ["avant la perte"], "history restored")
        XCTAssertEqual(alice2.contact(named: "bob")?.trust, .verified, "verification survives a restore")
        XCTAssertFalse(alice2.sessions.hasSession(contactId: bobId), "sessions are not restored")

        let net2 = SimNetwork()
        net2.connect(alice2.transport, bob.transport)
        _ = try alice2.messenger.sendText(to: bobId, text: "après la restauration")
        net2.pump()
        XCTAssertTrue(alice2.sessions.hasSession(contactId: bobId), "session renegotiated")
        XCTAssertEqual(bob.received.map { $0.text }, ["avant la perte", "après la restauration"])
        XCTAssertEqual(alice2.contact(named: "bob")?.trust, .verified)
    }

    func testRestoreWithWrongPhraseGivesDifferentIdentityAndUnreadableBackup() throws {
        let entropyA = Data(repeating: 1, count: 32), entropyB = Data(repeating: 2, count: 32)
        XCTAssertNotEqual(SoftIdentityCrypto(seed: entropyA).publicKey, SoftIdentityCrypto(seed: entropyB).publicKey)
        let file = try RecoveryBackup.seal(Data("x".utf8), entropy: entropyA)
        XCTAssertThrowsError(try RecoveryBackup.open(file, entropy: entropyB))
    }
}
