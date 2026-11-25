import XCTest
@testable import MeshCore

final class ContactFlowTests: XCTestCase {

    func testQRSignatureRoundTrip() {
        let id = SoftIdentityCrypto()
        let qr = ContactQR.make(crypto: id, displayName: "Alice", nowMs: 1_000)
        let decoded = ContactQR.decode(qr.encode())
        XCTAssertEqual(decoded, qr)
        XCTAssertTrue(decoded!.verify(crypto: id, nowMs: 1_000))
        XCTAssertTrue(qr.encode().hasPrefix("mesh1:"))
    }

    func testQRTamperingIsDetected() {
        let id = SoftIdentityCrypto(), other = SoftIdentityCrypto()
        let qr = ContactQR.make(crypto: id, displayName: "Alice", nowMs: 1_000)
        let renamed = ContactQR(identityKey: qr.identityKey, displayName: "Alicf", timestampMs: qr.timestampMs, signature: qr.signature)
        XCTAssertFalse(renamed.verify(crypto: id, nowMs: 1_000), "name changed")
        let rekeyed = ContactQR(identityKey: other.publicKey, displayName: "Alice", timestampMs: qr.timestampMs, signature: qr.signature)
        XCTAssertFalse(rekeyed.verify(crypto: id, nowMs: 1_000), "key swapped, signature of another key")
        let retimed = ContactQR(identityKey: qr.identityKey, displayName: "Alice", timestampMs: 2_000, signature: qr.signature)
        XCTAssertFalse(retimed.verify(crypto: id, nowMs: 2_000), "timestamp changed")
    }

    func testQRExpiresAndRejectsFuture() {
        let id = SoftIdentityCrypto()
        let qr = ContactQR.make(crypto: id, displayName: "Alice", nowMs: 1_000_000)
        XCTAssertTrue(qr.verify(crypto: id, nowMs: 1_000_000 + ContactQR.maxAgeMs))
        XCTAssertFalse(qr.verify(crypto: id, nowMs: 1_000_000 + ContactQR.maxAgeMs + 1), "a stale screenshot is refused")
        XCTAssertFalse(qr.verify(crypto: id, nowMs: 1_000_000 - ContactQR.maxAgeMs - 1))
    }

    func testQRDecodeRejectsGarbage() {
        XCTAssertNil(ContactQR.decode(""))
        XCTAssertNil(ContactQR.decode("mesh1:"))
        XCTAssertNil(ContactQR.decode("mesh1:%%%"))
        XCTAssertNil(ContactQR.decode("https://example.com"))
        let id = SoftIdentityCrypto()
        let good = ContactQR.make(crypto: id, displayName: "A", nowMs: 5).encode()
        XCTAssertNil(ContactQR.decode(String(good.dropLast(3))), "truncated")
        XCTAssertNil(ContactQR.decode(good + "AAAA"), "trailing bytes")
    }

    func testQRNameIsClamped() {
        let id = SoftIdentityCrypto()
        let qr = ContactQR.make(crypto: id, displayName: String(repeating: "é", count: 100), nowMs: 1)
        XCTAssertLessThanOrEqual(qr.displayName.utf8.count, ContactQR.maxNameBytes)
        XCTAssertTrue(ContactQR.decode(qr.encode())!.verify(crypto: id, nowMs: 1))
    }

    func testSecurityCodeIsSymmetricAndKeySensitive() {
        let a = SoftIdentityCrypto().publicKey, b = SoftIdentityCrypto().publicKey, c = SoftIdentityCrypto().publicKey
        let ab = SecurityCode.make(localKey: a, remoteKey: b)
        XCTAssertEqual(ab, SecurityCode.make(localKey: b, remoteKey: a), "both phones show the same code")
        XCTAssertNotEqual(ab, SecurityCode.make(localKey: a, remoteKey: c))
        XCTAssertEqual(ab.split(separator: " ").count, 6)
        XCTAssertTrue(ab.split(separator: " ").allSatisfy { $0.count == 5 && $0.allSatisfy { $0.isNumber } })
    }

    func testQRScanHandshakeVerifiesAndExchangesEncryptedText() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, bob) = makeVerifiedPair(net: net, clock: clock)

        let bobOnAlice = alice.contact(named: "bob")!
        XCTAssertEqual(bobOnAlice.status, .accepted)
        XCTAssertEqual(bobOnAlice.trust, .verified, "scanned in person + live challenge answered")
        let aliceOnBob = bob.contact(named: "alice")!
        XCTAssertEqual(aliceOnBob.status, .accepted)
        XCTAssertEqual(aliceOnBob.trust, .unverified, "Bob has not scanned Alice's QR code: still unverified")

        let sent = try! alice.messenger.sendText(to: bobOnAlice.id, text: "Bonjour Bob")
        net.pump()
        XCTAssertEqual(bob.received.map { $0.text }, ["Bonjour Bob"])
        XCTAssertEqual(alice.messenger.messages.all().first { $0.id == sent.id }?.state, .delivered,
                       "authenticated end-to-end receipt")

        _ = try! bob.messenger.sendText(to: aliceOnBob.id, text: "Salut Alice")
        net.pump()
        XCTAssertEqual(alice.received.map { $0.text }, ["Salut Alice"])
    }

    func testBobBecomesVerifiedByScanningAliceInPerson() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, bob) = makeVerifiedPair(net: net, clock: clock)
        try! bob.messenger.addContact(fromQR: alice.messenger.myQR())
        net.pump()
        XCTAssertEqual(bob.contact(named: "alice")?.trust, .verified)
    }

    func testRelayedHandshakeStillWorks() {
        let clock = TestClock(), net = SimNetwork()
        let alice = Device(name: "alice", clock: clock), bob = Device(name: "bob", clock: clock)
        let relay = Device(name: "relay", clock: clock)
        net.connect(alice.transport, relay.transport)
        net.connect(relay.transport, bob.transport)
        try! alice.messenger.addContact(fromQR: bob.messenger.myQR())
        net.pump()
        try! bob.messenger.acceptRequest(contactId: bob.requests.first!.id)
        net.pump()
        XCTAssertEqual(alice.contact(named: "bob")?.trust, .verified)
        XCTAssertTrue(relay.messenger.contacts.all().isEmpty, "the relay learns nothing")
        let c = alice.contact(named: "bob")!
        _ = try! alice.messenger.sendText(to: c.id, text: "2 sauts")
        net.pump()
        XCTAssertEqual(bob.received.map { $0.text }, ["2 sauts"])
        XCTAssertTrue(relay.received.isEmpty)
        let plain = Data("2 sauts".utf8)
        for e in relay.node.relay.entries() {
            XCTAssertNil(e.envelope.range(of: plain), "relayed envelopes carry only ciphertext")
        }
    }

    func testForgedBundleResponseDoesNotVerify() {

        let clock = TestClock(), net = SimNetwork()
        let alice = Device(name: "alice", clock: clock), bob = Device(name: "bob", clock: clock)
        let mallory = SoftIdentityCrypto()
        net.connect(alice.transport, bob.transport)
        try! alice.messenger.addContact(fromQR: bob.messenger.myQR())

        let nonceHex = alice.store.load("handshake").flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            .flatMap { $0["challenges"] as? [String: Any] }?.keys.first
        let nonce = Data(meshHex: nonceHex!)!
        let forged = Handshake.makeResponse(crypto: mallory, nonce: nonce, requesterKey: alice.crypto.publicKey,
                                            bundle: Data(repeating: 1, count: 32))
        let env = Envelope(kind: .inbox, bodyType: .bundle, ttl: 0,
                           tag: RoutingTags.inboxTag(identityPublic: alice.crypto.publicKey,
                                                     epoch: RoutingTags.epoch(atMs: clock.ms)), body: forged)
        let mallNode = Device(name: "mallory", clock: clock)
        net.connect(mallNode.transport, alice.transport)
        mallNode.node.enqueue(env)
        net.pump()
        XCTAssertNotEqual(alice.contact(named: "bob")?.trust, .verified)
        XCTAssertNotEqual(alice.contact(named: "bob")?.status, .accepted)
    }

    func testTamperedRequestIsIgnored() {
        let clock = TestClock(), net = SimNetwork()
        let bob = Device(name: "bob", clock: clock)
        let eve = SoftIdentityCrypto(), victim = SoftIdentityCrypto()
        var body = Handshake.makeRequest(crypto: eve, targetKey: bob.crypto.publicKey, name: "Eve",
                                         firstText: "hi", nonce: Data(repeating: 3, count: 16))

        body.replaceSubrange(17..<17 + 64, with: victim.publicKey)
        XCTAssertNil(Handshake.parseRequest(body, crypto: bob.crypto))
    }

    func testKeyChangeRemovesBadgeAndRaisesAlert() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, bob) = makeVerifiedPair(net: net, clock: clock)
        let before = alice.contact(named: "bob")!
        XCTAssertEqual(before.trust, .verified)

        let bob2 = Device(name: "bob2", clock: clock, displayName: "bob")
        net.connect(alice.transport, bob2.transport)
        let outcome = try! alice.messenger.addContact(fromQR: bob2.messenger.myQR())
        XCTAssertEqual(outcome, .keyChangeAlert(contactId: before.id))
        let after = alice.contact(named: "bob")!
        XCTAssertEqual(after.trust, .unverified, "badge removed")
        XCTAssertTrue(after.hasKeyChangeAlert)
        XCTAssertEqual(after.identityKey, before.identityKey, "the old key is kept until the user decides")
        XCTAssertEqual(alice.keyChanges.count, 1)
        _ = bob
    }

    func testKeyChangeViaIncomingRequest() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, _) = makeVerifiedPair(net: net, clock: clock)
        let impostor = Device(name: "impostor", clock: clock, displayName: "bob")
        net.connect(alice.transport, impostor.transport)
        try! impostor.messenger.addContact(fromQR: alice.messenger.myQR())
        net.pump()
        let c = alice.contact(named: "bob")!
        XCTAssertTrue(c.hasKeyChangeAlert)
        XCTAssertEqual(c.trust, .unverified)
        XCTAssertTrue(alice.requests.isEmpty, "an impostor is not offered as a normal request")
    }

    func testAcceptingKeyChangeReplacesKeyButStaysUnverified() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, _) = makeVerifiedPair(net: net, clock: clock)
        let bob2 = Device(name: "bob2", clock: clock, displayName: "bob")
        _ = try! alice.messenger.addContact(fromQR: bob2.messenger.myQR())
        let id = alice.contact(named: "bob")!.id
        alice.messenger.resolveKeyChange(contactId: id, accept: true)
        let c = alice.contact(named: "bob")!
        XCTAssertEqual(c.identityKey, bob2.crypto.publicKey)
        XCTAssertEqual(c.trust, .unverified)
        XCTAssertFalse(c.hasKeyChangeAlert)
        XCTAssertEqual(c.id, id, "the conversation is kept")
    }

    func testDismissingKeyChangeKeepsOldKey() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, bob) = makeVerifiedPair(net: net, clock: clock)
        let bob2 = Device(name: "bob2", clock: clock, displayName: "bob")
        _ = try! alice.messenger.addContact(fromQR: bob2.messenger.myQR())
        let id = alice.contact(named: "bob")!.id
        alice.messenger.resolveKeyChange(contactId: id, accept: false)
        XCTAssertEqual(alice.contact(named: "bob")!.identityKey, bob.crypto.publicKey)
        XCTAssertFalse(alice.contact(named: "bob")!.hasKeyChangeAlert)
    }

    func testStrangerHasOneRequestAndNoLinks() {
        let store = MemoryDocumentStore()
        let g = AbuseGuard(store: store)
        let key = Data(repeating: 9, count: 64)
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: "bonjour", nowMs: 0), .accept)
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: "regarde https://x.com", nowMs: 0), .rejectLink)
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: "va sur www.promo.cm", nowMs: 0), .rejectLink)
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: "promo.com/offre", nowMs: 0), .rejectLink)
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: String(repeating: "a", count: 600), nowMs: 0), .rejectTooLong)
        g.recordRequest(senderKey: key, nowMs: 0)
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: "re-bonjour", nowMs: 1), .rejectRequestLimit,
                       "a second request from the same stranger is refused")

        let g2 = AbuseGuard(store: store)
        XCTAssertEqual(g2.evaluateRequest(senderKey: key, text: "encore", nowMs: 2), .rejectRequestLimit)
    }

    func testBlocking() {
        let g = AbuseGuard(store: MemoryDocumentStore())
        let key = Data(repeating: 4, count: 64)
        g.block(key: key)
        XCTAssertTrue(g.isBlocked(key: key))
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: "hi", nowMs: 0), .rejectBlocked)
        g.unblock(key: key)
        XCTAssertEqual(g.evaluateRequest(senderKey: key, text: "hi", nowMs: 0), .accept)
    }

    func testLocalReportsStayOnDevice() {
        let g = AbuseGuard(store: MemoryDocumentStore())
        g.report(key: Data([1, 2]), reason: "spam", nowMs: 5)
        XCTAssertEqual(g.reports(), [LocalReport(keyHex: "0102", reason: "spam", atMs: 5)])
    }

    func testDailyLimitOfOutgoingStrangerRequests() {
        let clock = TestClock(), net = SimNetwork()
        let me = Device(name: "me", clock: clock)
        net.connect(me.transport, Device(name: "x", clock: clock).transport)
        for i in 0..<AbuseGuard.maxOutgoingStrangersPerDay {
            let other = SoftIdentityCrypto()
            let qr = ContactQR.make(crypto: other, displayName: "p\(i)", nowMs: clock.ms).encode()
            XCTAssertNoThrow(try me.messenger.addContact(fromQR: qr))
        }
        let extra = ContactQR.make(crypto: SoftIdentityCrypto(), displayName: "one-too-many", nowMs: clock.ms).encode()
        XCTAssertThrowsError(try me.messenger.addContact(fromQR: extra)) {
            XCTAssertEqual($0 as? MessengerError, .dailyLimitReached)
        }
        clock.ms += 86_400_000
        let nextDay = ContactQR.make(crypto: SoftIdentityCrypto(), displayName: "tomorrow", nowMs: clock.ms).encode()
        XCTAssertNoThrow(try me.messenger.addContact(fromQR: nextDay))
    }

    func testIncomingStrangerRequestIsSurfacedOnceAndLinksAreDropped() {
        let clock = TestClock(), net = SimNetwork()
        let bob = Device(name: "bob", clock: clock), spam = Device(name: "spam", clock: clock)
        net.connect(spam.transport, bob.transport)
        try! spam.messenger.addContact(fromQR: bob.messenger.myQR(), firstText: "gagne un prix sur http://x.com")
        net.pump()
        XCTAssertTrue(bob.requests.isEmpty, "a request carrying a link never reaches the user")
        try! spam.messenger.addContact(fromQR: bob.messenger.myQR(), firstText: "bonjour")
        net.pump()
        XCTAssertEqual(bob.requests.count, 1)
        XCTAssertEqual(bob.requests.first?.requestText, "bonjour")
    }

    func testRejectAndBlockRequest() {
        let clock = TestClock(), net = SimNetwork()
        let bob = Device(name: "bob", clock: clock), eve = Device(name: "eve", clock: clock)
        net.connect(eve.transport, bob.transport)
        try! eve.messenger.addContact(fromQR: bob.messenger.myQR(), firstText: "salut")
        net.pump()
        bob.messenger.rejectRequest(contactId: bob.requests.first!.id, block: true)
        XCTAssertTrue(bob.messenger.contacts.all().isEmpty)
        XCTAssertTrue(bob.messenger.abuse.isBlocked(key: eve.crypto.publicKey))
        try! eve.messenger.addContact(fromQR: bob.messenger.myQR(), firstText: "stp")
        net.pump()
        XCTAssertEqual(bob.requests.count, 1, "blocked: no new request is shown")
    }

    func testCannotSendBeforeAcceptance() {
        let clock = TestClock(), net = SimNetwork()
        let alice = Device(name: "alice", clock: clock), bob = Device(name: "bob", clock: clock)
        net.connect(alice.transport, bob.transport)
        let outcome = try! alice.messenger.addContact(fromQR: bob.messenger.myQR())
        guard case .requestSent(let id) = outcome else { return XCTFail() }
        XCTAssertThrowsError(try alice.messenger.sendText(to: id, text: "trop tôt")) {
            XCTAssertEqual($0 as? MessengerError, .notAccepted)
        }
    }

    func testOwnQRAndInvalidInput() {
        let clock = TestClock()
        let alice = Device(name: "alice", clock: clock)
        XCTAssertThrowsError(try alice.messenger.addContact(fromQR: alice.messenger.myQR())) {
            XCTAssertEqual($0 as? MessengerError, .ownKey)
        }
        XCTAssertThrowsError(try alice.messenger.addContact(fromQR: "nimporte quoi")) {
            XCTAssertEqual($0 as? MessengerError, .invalidOrExpiredQR)
        }
        let old = ContactQR.make(crypto: SoftIdentityCrypto(), displayName: "x", nowMs: clock.ms - 20 * 60_000).encode()
        XCTAssertThrowsError(try alice.messenger.addContact(fromQR: old)) {
            XCTAssertEqual($0 as? MessengerError, .invalidOrExpiredQR)
        }
    }

    func testEmptyAndOversizedTexts() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, _) = makeVerifiedPair(net: net, clock: clock)
        let id = alice.contact(named: "bob")!.id
        XCTAssertThrowsError(try alice.messenger.sendText(to: id, text: "   ")) {
            XCTAssertEqual($0 as? MessengerError, .emptyText)
        }
        XCTAssertThrowsError(try alice.messenger.sendText(to: id, text: String(repeating: "a", count: MeshMessenger.maxTextBytes + 1))) {
            XCTAssertEqual($0 as? MessengerError, .textTooLong)
        }
    }

    func testBlockedContactMessagesAreDropped() {
        let clock = TestClock(), net = SimNetwork()
        let (alice, bob) = makeVerifiedPair(net: net, clock: clock)
        bob.messenger.contacts.setBlocked(id: bob.contact(named: "alice")!.id, true)
        _ = try! alice.messenger.sendText(to: alice.contact(named: "bob")!.id, text: "ignoré")
        net.pump()
        XCTAssertTrue(bob.received.isEmpty)
    }
}
