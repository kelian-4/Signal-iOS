import Foundation

public let maxClientLinks = 2
public let idleDisconnectMs: Int64 = 20_000

public func shouldConnect(pending: Bool, readyLinks: Int, clientLinks: Int, nowMs: Int64,
                          nextConnectAtMs: Int64, ignoreUntilMs: Int64, inboundFromPeer: Bool = false) -> Bool {
    return pending && readyLinks == 0 && clientLinks < maxClientLinks
        && nowMs >= nextConnectAtMs && nowMs >= ignoreUntilMs && !inboundFromPeer
}

public func shouldDropIdle(ready: Bool, pending: Bool, nowMs: Int64, lastActivityMs: Int64) -> Bool {
    return ready && !pending && nowMs - lastActivityMs >= idleDisconnectMs
}
