import XCTest
@testable import MeshCore

final class OutboxRelayTests: XCTestCase {
    func testOutboxPersistsAcrossRestart() {
        let store = MemoryDocumentStore()
        let o1 = Outbox(store: store)
        o1.add(OutboxEntry(msgId: "0000000000000001", envelope: Data([1, 2, 3]), createdMs: 10))
        o1.add(OutboxEntry(msgId: "0000000000000002", envelope: Data([4]), createdMs: 5))
        XCTAssertTrue(o1.markSent("0000000000000001", nowMs: 20))
        let o2 = Outbox(store: store)
        XCTAssertEqual(o2.entries().map { $0.msgId }, ["0000000000000002", "0000000000000001"])
        XCTAssertEqual(o2.entry("0000000000000001")?.state, .sent)
        XCTAssertEqual(o2.pending().count, 2)
    }

    func testOutboxStateMachine() {
        let o = Outbox(store: MemoryDocumentStore())
        o.add(OutboxEntry(msgId: "aa", envelope: Data(), createdMs: 0))
        XCTAssertTrue(o.markSent("aa", nowMs: 1))
        XCTAssertFalse(o.markSent("aa", nowMs: 2), "second hop ACK does not change the state")
        XCTAssertTrue(o.markDelivered("aa", nowMs: 3))
        XCTAssertFalse(o.markDelivered("aa", nowMs: 4))
        XCTAssertTrue(o.pending().isEmpty, "delivered entries leave the queue")
    }

    func testOutboxExpiry() {
        let o = Outbox(store: MemoryDocumentStore())
        o.add(OutboxEntry(msgId: "old", envelope: Data(), createdMs: 100))
        o.add(OutboxEntry(msgId: "new", envelope: Data(), createdMs: 900))
        let expired = o.expire(olderThanMs: 500)
        XCTAssertEqual(expired, ["old"])
        XCTAssertEqual(o.entry("old")?.state, .expired)
        XCTAssertEqual(o.pending().map { $0.msgId }, ["new"])
    }

    func testRelayCacheDedupAndEntryLimit() {
        let c = RelayCache(maxEntries: 3, maxBytes: 1_000_000, ttlMs: 10_000)
        XCTAssertTrue(c.insert(msgId: "1", envelope: Data([1]), nowMs: 1))
        XCTAssertFalse(c.insert(msgId: "1", envelope: Data([1]), nowMs: 2), "same msgId is not stored twice")
        for i in 2...5 { c.insert(msgId: String(i), envelope: Data([UInt8(i)]), nowMs: Int64(i)) }
        XCTAssertEqual(c.count, 3)
        XCTAssertFalse(c.contains("1"), "oldest entries are evicted first")
        XCTAssertFalse(c.contains("2"))
        XCTAssertTrue(c.contains("5"))
    }

    func testRelayCacheByteLimit() {
        let c = RelayCache(maxEntries: 100, maxBytes: 100, ttlMs: 10_000)
        for i in 0..<10 { c.insert(msgId: String(i), envelope: Data(repeating: 1, count: 30), nowMs: Int64(i)) }
        XCTAssertLessThanOrEqual(c.byteCount, 100)
        XCTAssertEqual(c.count, 3)
    }

    func testRelayCacheTTLAndHandoffs() {
        let c = RelayCache(maxEntries: 10, maxBytes: 1000, ttlMs: 1000)
        c.insert(msgId: "a", envelope: Data([1]), nowMs: 0)
        c.noteHandoff("a")
        XCTAssertTrue(c.hasEntriesToForward(maxHandoffs: 2))
        c.noteHandoff("a")
        XCTAssertFalse(c.hasEntriesToForward(maxHandoffs: 2))
        c.gc(nowMs: 999)
        XCTAssertTrue(c.contains("a"))
        c.gc(nowMs: 1000)
        XCTAssertFalse(c.contains("a"))
    }

    func testEnvelopeRoundTripAndLimits() {
        let e = Envelope(kind: .direct, bodyType: .ciphertext, ttl: 5, tag: Data(repeating: 7, count: 8), body: Data([9, 9]))
        XCTAssertEqual(Envelope.decode(e.encode()), e)
        XCTAssertEqual(e.decremented().ttl, 4)
        XCTAssertEqual(Envelope(kind: .inbox, bodyType: .bundle, ttl: 0, tag: e.tag, body: Data()).decremented().ttl, 0)
        XCTAssertNil(Envelope.decode(Data(repeating: 0, count: 5)))
        var bad = e.encode(); bad[0] = 9
        XCTAssertNil(Envelope.decode(bad), "unknown version")
        var badKind = e.encode(); badKind[1] = 77
        XCTAssertNil(Envelope.decode(badKind))
        let huge = Envelope(kind: .direct, bodyType: .ciphertext, ttl: 1, tag: e.tag,
                            body: Data(count: Envelope.maxBodySize + 1))
        XCTAssertNil(Envelope.decode(huge.encode()))
    }

    func testRoutingTagsAreEphemeralAndPerContact() {
        let secretAB = RoutingTags.routingSecret(fromSharedSecret: Data(repeating: 1, count: 32))
        let secretAC = RoutingTags.routingSecret(fromSharedSecret: Data(repeating: 2, count: 32))
        let pub = Data(repeating: 5, count: 33)
        let t0 = RoutingTags.directTag(routingSecret: secretAB, recipientPublic: pub, epoch: 100)
        XCTAssertEqual(t0.count, RoutingTags.tagSize)
        XCTAssertNotEqual(t0, RoutingTags.directTag(routingSecret: secretAB, recipientPublic: pub, epoch: 101),
                          "the tag changes every epoch")
        XCTAssertNotEqual(t0, RoutingTags.directTag(routingSecret: secretAC, recipientPublic: pub, epoch: 100),
                          "different contacts never share a tag")
        XCTAssertNotEqual(RoutingTags.inboxTag(identityPublic: pub, epoch: 1), RoutingTags.inboxTag(identityPublic: pub, epoch: 2))
        XCTAssertEqual(RoutingTags.acceptedEpochs(nowMs: 3_600_000 * 10 + 5), [9, 10, 11])
        XCTAssertEqual(RoutingTags.receiptMac(routingSecret: secretAB, msgId: Data(count: 8)).count, 16)
        XCTAssertNotEqual(RoutingTags.receiptMac(routingSecret: secretAB, msgId: Data(count: 8)),
                          RoutingTags.receiptMac(routingSecret: secretAC, msgId: Data(count: 8)))
    }
}
