import Foundation

public final class MeshNode: TransportDelegate {
    public struct Config {

        public var ackTimeoutMs: Int64 = 15_000
        public var outboxTTLms: Int64 = 7 * 24 * 3_600_000
        public var initialTTL: UInt8 = 6

        public var maxRelayHandoffs = 3
        public var seenTTLms: Int64 = Proto.dedupTTLms

        public var resetCooldownMs: Int64 = 10_000
        public init() {}
    }

    private struct Link {
        var maxFrameSize: Int
        let reassembler = Reassembler()
        var inflight: [String: Int64] = [:]
        var acked: Set<String> = []
        var connectedMs: Int64
        var lastRxMs: Int64
        var lastResetMs: Int64 = 0
    }

    public let config: Config
    public let outbox: Outbox
    public let relay: RelayCache
    public weak var delegate: MeshNodeDelegate?
    public var logger: MeshLogger = NullLogger()

    public var isForMe: (Envelope) -> Bool = { _ in false }

    private let transport: Transport
    private let nowMs: NowMs
    private var links: [String: Link] = [:]
    private var seen: [String: Int64] = [:]

    public init(transport: Transport, outbox: Outbox, relay: RelayCache = RelayCache(),
                config: Config = Config(), now: @escaping NowMs = systemNowMs) {
        self.transport = transport
        self.outbox = outbox
        self.relay = relay
        self.config = config
        self.nowMs = now
        for e in outbox.entries() { seen[e.msgId] = e.createdMs }
        transport.delegate = self
    }

    public var readyLinkCount: Int { return links.count }

    public var hasPendingWork: Bool {
        return !outbox.pending().isEmpty || relay.hasEntriesToForward(maxHandoffs: config.maxRelayHandoffs)
    }

    @discardableResult
    public func enqueue(_ envelope: Envelope) -> String {
        let id = MeshNode.randomMsgId()
        let hex = id.toHex()
        let withTTL = Envelope(kind: envelope.kind, bodyType: envelope.bodyType, ttl: config.initialTTL,
                               tag: envelope.tag, body: envelope.body)
        outbox.add(OutboxEntry(msgId: hex, envelope: withTTL.encode(), createdMs: nowMs()))
        seen[hex] = nowMs()
        for linkId in Array(links.keys) { pushPending(on: linkId) }
        return hex
    }

    public func markDelivered(msgIdHex: String) {
        if outbox.markDelivered(msgIdHex, nowMs: nowMs()) {
            delegate?.node(self, outboxDidChange: msgIdHex, state: .delivered)
        }
    }

    private static func randomMsgId() -> Data {
        var bytes = [UInt8]()
        for _ in 0..<Proto.msgIdSize { bytes.append(UInt8.random(in: 0...255)) }
        return Data(bytes)
    }

    private func pushPending(on linkId: String) {
        guard let link = links[linkId] else { return }
        for e in outbox.pending() where !link.acked.contains(e.msgId) && links[linkId]?.inflight[e.msgId] == nil {
            outbox.noteAttempt(e.msgId)
            transmit(msgIdHex: e.msgId, envelope: e.envelope, on: linkId)
        }
        for r in relay.entries() where r.handoffs < config.maxRelayHandoffs
            && !link.acked.contains(r.msgId) && links[linkId]?.inflight[r.msgId] == nil {
            transmit(msgIdHex: r.msgId, envelope: r.envelope, on: linkId)
        }
    }

    private func transmit(msgIdHex: String, envelope: Data, on linkId: String) {
        guard var link = links[linkId], let msgId = Data(meshHex: msgIdHex) else { return }
        guard let frames = try? fragment(payload: envelope, maxFrameSize: link.maxFrameSize, msgId: msgId) else { return }
        link.inflight[msgIdHex] = nowMs()
        links[linkId] = link
        for f in frames {
            if !transport.send(f.encode(), on: linkId) { break }
        }
    }

    private func sendAck(_ msgId: Data, on linkId: String) {
        _ = transport.send(Frame.ack(msgId: msgId).encode(), on: linkId)
    }

    public func transportDidConnect(link linkId: String, maxFrameSize: Int) {
        let t = nowMs()
        links[linkId] = Link(maxFrameSize: maxFrameSize, connectedMs: t, lastRxMs: t)
        logger.log("link_up", ["link": linkId, "mtu": String(maxFrameSize)])
        pushPending(on: linkId)
    }

    public func transportDidDisconnect(link linkId: String) {
        if links.removeValue(forKey: linkId) != nil {
            logger.log("link_down", ["link": linkId])
        }
    }

    public func transportDidReceive(_ data: Data, on linkId: String) {
        guard let link = links[linkId] else { return }
        let t = nowMs()
        links[linkId]?.lastRxMs = t
        switch link.reassembler.accept(data, nowMs: t) {
        case .partial, .invalid:
            break
        case .ack(let id):
            handleAck(id.toHex(), on: linkId)
        case .duplicate(let id):
            sendAck(id, on: linkId)
        case .complete(let id, let payload):
            sendAck(id, on: linkId)
            handleEnvelope(payload, msgId: id, from: linkId)
        }
    }

    private func handleAck(_ hex: String, on linkId: String) {
        links[linkId]?.inflight[hex] = nil
        links[linkId]?.acked.insert(hex)
        if outbox.markSent(hex, nowMs: nowMs()) {
            delegate?.node(self, outboxDidChange: hex, state: .sent)
        }
        if relay.contains(hex) { relay.noteHandoff(hex) }
    }

    private func handleEnvelope(_ payload: Data, msgId: Data, from linkId: String) {
        let hex = msgId.toHex()
        let t = nowMs()
        if seen[hex] != nil { return }
        guard let env = Envelope.decode(payload) else { return }
        seen[hex] = t
        if isForMe(env) {
            delegate?.node(self, didReceive: env, msgId: msgId)
            return
        }
        guard env.ttl > 0 else { return }
        relay.insert(msgId: hex, envelope: env.decremented().encode(), nowMs: t)
        for other in Array(links.keys) where other != linkId { pushPending(on: other) }
    }

    public func tick() {
        let t = nowMs()
        seen = seen.filter { t - $0.value < config.seenTTLms }
        relay.gc(nowMs: t)
        for id in outbox.expire(olderThanMs: t - config.outboxTTLms) {
            delegate?.node(self, outboxDidChange: id, state: .expired)
        }
        for (linkId, link) in links {
            guard let oldest = link.inflight.values.min() else { continue }
            if t - oldest >= config.ackTimeoutMs && t - link.lastResetMs >= config.resetCooldownMs {
                logger.log("watchdog_reset", [
                    "link": linkId,
                    "inflight": String(link.inflight.count),
                    "silent_ms": String(t - link.lastRxMs),
                ])
                links[linkId]?.inflight = [:]
                links[linkId]?.lastResetMs = t
                transport.reset(link: linkId)
            }
        }
    }
}
