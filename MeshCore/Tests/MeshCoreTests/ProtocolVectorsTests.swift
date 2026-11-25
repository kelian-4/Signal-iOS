import XCTest
@testable import MeshCore

final class ProtocolVectorsTests: XCTestCase {
    private var vectors: [String: Any] = [:]

    override func setUpWithError() throws {
        guard let url = Bundle.module.url(forResource: "vectors", withExtension: "json") else {
            XCTFail("vectors.json missing from the test bundle")
            return
        }
        let data = try Data(contentsOf: url)
        vectors = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func list(_ key: String) -> [[String: Any]] {
        return (vectors[key] as? [[String: Any]]) ?? []
    }

    func testConstantsMatchSpec() {
        XCTAssertEqual(vectors["version"] as? Int, Int(Proto.version))
        XCTAssertEqual(vectors["header_size"] as? Int, Proto.headerSize)
        XCTAssertEqual((vectors["partial_ttl_ms"] as? NSNumber)?.int64Value, Proto.partialTTLms)
        XCTAssertEqual((vectors["dedup_ttl_ms"] as? NSNumber)?.int64Value, Proto.dedupTTLms)
    }

    func testFrameEncoding() throws {
        let cases = list("frame_encoding")
        XCTAssertFalse(cases.isEmpty)
        for c in cases {
            let name = c["name"] as? String ?? "?"
            let frame = Frame(type: UInt8(c["type"] as! Int),
                              msgId: Data(meshHex: c["msg_id_hex"] as! String)!,
                              fragIndex: c["frag_index"] as! Int,
                              fragTotal: c["frag_total"] as! Int,
                              payload: Data(meshHex: c["payload_hex"] as! String)!)
            let expected = Data(meshHex: c["frame_hex"] as! String)!
            XCTAssertEqual(frame.encode(), expected, "encode \(name)")
            XCTAssertEqual(Frame.decode(expected), frame, "decode \(name)")
        }
    }

    func testInvalidFramesAreRejected() {
        let cases = list("frame_invalid")
        XCTAssertFalse(cases.isEmpty)
        for c in cases {
            let data = Data(meshHex: c["frame_hex"] as! String)!
            XCTAssertNil(Frame.decode(data), "invalid frame accepted: \(c["name"] as? String ?? "?")")
        }
    }

    func testFragmentation() throws {
        let cases = list("fragmentation")
        XCTAssertFalse(cases.isEmpty)
        for c in cases {
            let name = c["name"] as? String ?? "?"
            let text = c["text"] as! String
            let frames = try fragment(payload: Data(text.utf8), maxFrameSize: c["max_frame_size"] as! Int,
                                      msgId: Data(meshHex: c["msg_id_hex"] as! String)!)
            let expected = (c["frames_hex"] as! [String]).map { Data(meshHex: $0)! }
            XCTAssertEqual(frames.map { $0.encode() }, expected, "fragmentation \(name)")
            for f in frames { XCTAssertLessThanOrEqual(f.encode().count, c["max_frame_size"] as! Int, name) }
        }
    }

    func testFrameSizeTooSmallThrows() {
        XCTAssertThrowsError(try fragment(payload: Data([1]), maxFrameSize: Proto.headerSize,
                                          msgId: Data(count: 8)))
    }

    func testReassembly() {
        let cases = list("reassembly")
        XCTAssertFalse(cases.isEmpty)
        for c in cases {
            let name = c["name"] as? String ?? "?"
            let r = Reassembler()
            for (i, step) in (c["steps"] as! [[String: Any]]).enumerated() {
                let t = (step["t_ms"] as! NSNumber).int64Value
                let got = r.accept(Data(meshHex: step["frame_hex"] as! String)!, nowMs: t)
                let label = "\(name) step \(i)"
                switch step["expect"] as! String {
                case "partial": XCTAssertEqual(got, .partial, label)
                case "invalid": XCTAssertEqual(got, .invalid, label)
                case "ack": XCTAssertEqual(got, .ack(msgId: Data(meshHex: step["msg_id_hex"] as! String)!), label)
                case "duplicate": XCTAssertEqual(got, .duplicate(msgId: Data(meshHex: step["msg_id_hex"] as! String)!), label)
                case "complete":
                    XCTAssertEqual(got, .complete(msgId: Data(meshHex: step["msg_id_hex"] as! String)!,
                                                  payload: Data(meshHex: step["payload_hex"] as! String)!), label)
                default: XCTFail("unknown expectation in \(label)")
                }
            }
        }
    }

    func testConnectionPolicy() {
        let policy = vectors["connection_policy"] as! [String: Any]
        XCTAssertEqual(policy["max_client_links"] as? Int, maxClientLinks)
        XCTAssertEqual((policy["idle_disconnect_ms"] as? NSNumber)?.int64Value, idleDisconnectMs)
        for c in policy["should_connect"] as! [[String: Any]] {
            let got = shouldConnect(pending: c["pending"] as! Bool, readyLinks: c["ready_links"] as! Int,
                                    clientLinks: c["client_links"] as! Int, nowMs: (c["now_ms"] as! NSNumber).int64Value,
                                    nextConnectAtMs: (c["next_connect_at_ms"] as! NSNumber).int64Value,
                                    ignoreUntilMs: (c["ignore_until_ms"] as! NSNumber).int64Value,
                                    inboundFromPeer: c["inbound_from_peer"] as! Bool)
            XCTAssertEqual(got, c["expect"] as! Bool, "should_connect \(c["name"] as? String ?? "?")")
        }
        for c in policy["should_drop_idle"] as! [[String: Any]] {
            let got = shouldDropIdle(ready: c["ready"] as! Bool, pending: c["pending"] as! Bool,
                                     nowMs: (c["now_ms"] as! NSNumber).int64Value,
                                     lastActivityMs: (c["last_activity_ms"] as! NSNumber).int64Value)
            XCTAssertEqual(got, c["expect"] as! Bool, "should_drop_idle \(c["name"] as? String ?? "?")")
        }
    }
}
