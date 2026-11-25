import Foundation

public enum Handshake {
    public static let nonceSize = 16
    public static let maxNameBytes = ContactQR.maxNameBytes

    public struct Request: Equatable {
        public let nonce: Data
        public let requesterKey: Data
        public let requesterName: String
        public let firstText: String
        public let signature: Data
    }

    private static func requestSigned(nonce: Data, target: Data, requester: Data, name: Data, text: Data) -> Data {
        var w = ByteWriter()
        w.raw(Data("mesh-req-v1".utf8))
        w.raw(nonce)
        w.bytes8(target)
        w.bytes8(requester)
        w.bytes8(name)
        w.bytes16(text)
        return w.data
    }

    public static func makeRequest(crypto: IdentityCrypto, targetKey: Data, name: String, firstText: String,
                                   nonce: Data) -> Data {
        let n = ContactQR.clampName(name)
        let t = Data(firstText.utf8.prefix(512))
        var w = ByteWriter()
        w.raw(nonce)
        w.bytes8(crypto.publicKey)
        w.bytes8(n)
        w.bytes16(t)
        w.bytes8(crypto.sign(requestSigned(nonce: nonce, target: targetKey, requester: crypto.publicKey, name: n, text: t)))
        return w.data
    }

    public static func parseRequest(_ body: Data, crypto: IdentityCrypto) -> Request? {
        var r = ByteReader(body)
        guard let nonce = r.raw(nonceSize),
              let key = r.bytes8(), !key.isEmpty,
              let nameData = r.bytes8(), nameData.count <= maxNameBytes,
              let text = r.bytes16(), text.count <= 512,
              let sig = r.bytes8(), r.remaining == 0,
              let name = String(data: nameData, encoding: .utf8),
              let firstText = String(data: text, encoding: .utf8) else { return nil }
        let signed = requestSigned(nonce: nonce, target: crypto.publicKey, requester: key, name: nameData, text: text)
        guard crypto.verify(publicKey: key, message: signed, signature: sig) else { return nil }
        return Request(nonce: nonce, requesterKey: key, requesterName: name, firstText: firstText, signature: sig)
    }

    public struct Response: Equatable {
        public let nonce: Data
        public let bundle: Data
        public let signature: Data
    }

    private static func responseSigned(nonce: Data, requester: Data, bundle: Data) -> Data {
        var w = ByteWriter()
        w.raw(Data("mesh-bundle-v1".utf8))
        w.raw(nonce)
        w.bytes8(requester)
        w.bytes16(bundle)
        return w.data
    }

    public static func makeResponse(crypto: IdentityCrypto, nonce: Data, requesterKey: Data, bundle: Data) -> Data {
        var w = ByteWriter()
        w.raw(nonce)
        w.bytes16(bundle)
        w.bytes8(crypto.sign(responseSigned(nonce: nonce, requester: requesterKey, bundle: bundle)))
        return w.data
    }

    public static func peekNonce(_ body: Data) -> Data? {
        return body.count >= nonceSize ? Data(body.prefix(nonceSize)) : nil
    }

    public static func parseResponse(_ body: Data, crypto: IdentityCrypto, targetKey: Data, expectedNonce: Data) -> Response? {
        var r = ByteReader(body)
        guard let nonce = r.raw(nonceSize), nonce == expectedNonce,
              let bundle = r.bytes16(), let sig = r.bytes8(), r.remaining == 0 else { return nil }
        let signed = responseSigned(nonce: nonce, requester: crypto.publicKey, bundle: bundle)
        guard crypto.verify(publicKey: targetKey, message: signed, signature: sig) else { return nil }
        return Response(nonce: nonce, bundle: bundle, signature: sig)
    }
}
