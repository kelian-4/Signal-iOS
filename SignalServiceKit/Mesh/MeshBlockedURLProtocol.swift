import Foundation

public final class MeshBlockedURLProtocol: URLProtocol {
    override public class func canInit(with request: URLRequest) -> Bool { true }

    override public class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override public func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
    }

    override public func stopLoading() {}
}
