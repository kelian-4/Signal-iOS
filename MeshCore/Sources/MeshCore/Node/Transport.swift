import Foundation

public protocol Transport: AnyObject {
    var delegate: TransportDelegate? { get set }

    func send(_ frame: Data, on linkId: String) -> Bool

    func reset(link linkId: String)
}

public protocol TransportDelegate: AnyObject {
    func transportDidConnect(link: String, maxFrameSize: Int)
    func transportDidDisconnect(link: String)
    func transportDidReceive(_ data: Data, on link: String)
}

public protocol MeshLogger: AnyObject {
    func log(_ event: String, _ fields: [String: String])
}

public final class NullLogger: MeshLogger {
    public init() {}
    public func log(_ event: String, _ fields: [String: String]) {}
}

public protocol MeshNodeDelegate: AnyObject {

    func node(_ node: MeshNode, didReceive envelope: Envelope, msgId: Data)

    func node(_ node: MeshNode, outboxDidChange msgId: String, state: OutboxState)
}
