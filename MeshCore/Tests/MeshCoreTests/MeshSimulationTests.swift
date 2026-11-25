import XCTest
@testable import MeshCore

final class MeshSimulationTests: XCTestCase {

    final class Probe: MeshNodeDelegate {
        let name: String
        let transport: SimTransport
        let node: MeshNode
        let tag: Data
        var got: [Envelope] = []
        var states: [String: OutboxState] = [:]

        init(name: String, clock: TestClock, config: MeshNode.Config = MeshNode.Config(),
             store: MemoryDocumentStore = MemoryDocumentStore()) {
            self.name = name
            self.tag = Data(name.utf8).prefix(8) + Data(count: max(0, 8 - name.utf8.count))
            transport = SimTransport(name: name)
            node = MeshNode(transport: transport, outbox: Outbox(store: store), relay: RelayCache(),
                            config: config, now: clock.now)
            node.delegate = self
            let myTag = tag
            node.isForMe = { $0.tag == myTag }
        }

        func node(_ node: MeshNode, didReceive envelope: Envelope, msgId: Data) { got.append(envelope) }
        func node(_ node: MeshNode, outboxDidChange msgId: String, state: OutboxState) { states[msgId] = state }

        func send(to other: Probe, text: String) -> String {
            let env = Envelope(kind: .direct, bodyType: .ciphertext, ttl: 0, tag: other.tag, body: Data(text.utf8))
            return node.enqueue(env)
        }
    }

    func testDirectDeliveryAndHopAck() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, b.transport)
        let id = a.send(to: b, text: "salut")
        net.pump()
        XCTAssertEqual(b.got.map { String(decoding: $0.body, as: UTF8.self) }, ["salut"])
        XCTAssertEqual(a.states[id], .sent, "hop ACK received")
    }

    func testMessageQueuedWhileOfflineIsDeliveredOnConnect() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), b = Probe(name: "bob", clock: clock)
        _ = a.send(to: b, text: "plus tard")
        XCTAssertTrue(a.node.hasPendingWork)
        net.pump()
        XCTAssertTrue(b.got.isEmpty)
        net.connect(a.transport, b.transport)
        net.pump()
        XCTAssertEqual(b.got.count, 1)
    }

    func testOutboxSurvivesRestart() {
        let clock = TestClock(), net = SimNetwork()
        let store = MemoryDocumentStore()
        let a1 = Probe(name: "alice", clock: clock, store: store)
        let b = Probe(name: "bob", clock: clock)
        _ = a1.send(to: b, text: "survit")

        let a2 = Probe(name: "alice", clock: clock, store: store)
        net.connect(a2.transport, b.transport)
        net.pump()
        XCTAssertEqual(b.got.map { String(decoding: $0.body, as: UTF8.self) }, ["survit"])
    }

    func testLargeMessageIsFragmentedAndReassembled() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, b.transport, mtu: 23)
        let text = String(repeating: "é", count: 500)
        _ = a.send(to: b, text: text)
        net.pump()
        XCTAssertEqual(b.got.first.map { String(decoding: $0.body, as: UTF8.self) }, text)
    }

    func testTwoHopRelayThroughThirdPhone() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), r = Probe(name: "relay", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, r.transport)
        net.connect(r.transport, b.transport)
        _ = a.send(to: b, text: "via relais")
        net.pump()
        XCTAssertEqual(b.got.map { String(decoding: $0.body, as: UTF8.self) }, ["via relais"])
        XCTAssertTrue(r.got.isEmpty, "the relay is not the recipient")
        XCTAssertEqual(r.node.relay.count, 1)
    }

    func testRelayCarriesMessageToLaterNeighbour() {

        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), r = Probe(name: "relay", clock: clock), b = Probe(name: "bob", clock: clock)
        let l1 = net.connect(a.transport, r.transport)
        _ = a.send(to: b, text: "porté")
        net.pump()
        net.cut(l1)
        XCTAssertTrue(b.got.isEmpty)
        net.connect(r.transport, b.transport)
        net.pump()
        XCTAssertEqual(b.got.map { String(decoding: $0.body, as: UTF8.self) }, ["porté"])
    }

    func testNoDuplicateDeliveryInTriangle() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), r = Probe(name: "relay", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, r.transport)
        net.connect(r.transport, b.transport)
        net.connect(a.transport, b.transport)
        _ = a.send(to: b, text: "une seule fois")
        net.pump()
        XCTAssertEqual(b.got.count, 1, "msgId de-duplication across two paths")
    }

    func testTTLLimitsHops() {
        let clock = TestClock(), net = SimNetwork()
        var cfg = MeshNode.Config(); cfg.initialTTL = 2
        let a = Probe(name: "alice", clock: clock, config: cfg)
        let h1 = Probe(name: "hop1", clock: clock), h2 = Probe(name: "hop2", clock: clock)
        let h3 = Probe(name: "hop3", clock: clock), far = Probe(name: "far", clock: clock)
        net.connect(a.transport, h1.transport)
        net.connect(h1.transport, h2.transport)
        net.connect(h2.transport, h3.transport)
        net.connect(h3.transport, far.transport)
        _ = a.send(to: far, text: "trop loin")
        net.pump()
        XCTAssertTrue(far.got.isEmpty, "TTL 2 stops the envelope before the 4th hop")
        XCTAssertEqual(h3.node.relay.count, 0, "a TTL-0 envelope is not cached")
    }

    func testRelayCannotReadPayload() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), r = Probe(name: "relay", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, r.transport)
        net.connect(r.transport, b.transport)
        _ = a.send(to: b, text: "secret")
        net.pump()
        let cached = r.node.relay.entries().first!.envelope
        let env = Envelope.decode(cached)!
        XCTAssertEqual(env.tag, b.tag, "only the opaque tag is visible to relays")
        XCTAssertEqual(env.ttl, MeshNode.Config().initialTTL - 1)
    }

    func testWatchdogResetsFrozenLinkAndRecovers() {

        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, b.transport)
        net.frozen.insert("bob")
        for i in 0..<5 { _ = a.send(to: b, text: "m\(i)") }
        net.pump()
        XCTAssertTrue(b.got.isEmpty)
        clock.ms += 5_000
        a.node.tick()
        XCTAssertTrue(a.transport.resets.isEmpty, "not yet: ACK timeout is 15 s")
        clock.ms += 11_000
        a.node.tick()
        XCTAssertEqual(a.transport.resets.count, 1, "no ACK for 16 s: the link is cut")
        XCTAssertEqual(a.node.readyLinkCount, 0)

        net.frozen.removeAll()
        net.connect(a.transport, b.transport)
        net.pump()
        XCTAssertEqual(Set(b.got.map { String(decoding: $0.body, as: UTF8.self) }), Set((0..<5).map { "m\($0)" }))
    }

    func testWatchdogDoesNotResetHealthyLink() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, b.transport)
        _ = a.send(to: b, text: "ok")
        net.pump()
        clock.ms += 60_000
        a.node.tick()
        XCTAssertTrue(a.transport.resets.isEmpty)
    }

    func testLostFragmentIsRecoveredByWatchdog() {
        let clock = TestClock(), net = SimNetwork()
        let a = Probe(name: "alice", clock: clock), b = Probe(name: "bob", clock: clock)
        net.connect(a.transport, b.transport, mtu: 30)
        var dropped = false
        net.dropFilter = { frame in
            if !dropped, let f = Frame.decode(frame), f.type == Proto.typeText, f.fragIndex == 1 {
                dropped = true
                return true
            }
            return false
        }
        _ = a.send(to: b, text: String(repeating: "x", count: 200))
        net.pump()
        XCTAssertTrue(b.got.isEmpty, "one fragment is missing")
        clock.ms += 16_000
        a.node.tick()
        net.connect(a.transport, b.transport, mtu: 30)
        net.pump()
        XCTAssertEqual(b.got.count, 1)
        XCTAssertEqual(b.got.first?.body.count, 200)
    }

    func testOldOutboxEntriesExpire() {
        let clock = TestClock(), net = SimNetwork()
        _ = net
        let a = Probe(name: "alice", clock: clock), b = Probe(name: "bob", clock: clock)
        let id = a.send(to: b, text: "périmé")
        clock.ms += MeshNode.Config().outboxTTLms + 1
        a.node.tick()
        XCTAssertEqual(a.states[id], .expired)
        XCTAssertFalse(a.node.hasPendingWork)
    }

    func testChainOfTenPhones() {
        let clock = TestClock(), net = SimNetwork()
        var cfg = MeshNode.Config(); cfg.initialTTL = 8
        let phones = (0..<10).map { Probe(name: "p\($0)", clock: clock, config: cfg) }
        for i in 0..<9 { net.connect(phones[i].transport, phones[i + 1].transport) }
        _ = phones[0].send(to: phones[9], text: "bout à bout")
        net.pump()
        XCTAssertEqual(phones[9].got.count, 1)
        for p in phones[1..<9] { XCTAssertTrue(p.got.isEmpty) }
    }
}
