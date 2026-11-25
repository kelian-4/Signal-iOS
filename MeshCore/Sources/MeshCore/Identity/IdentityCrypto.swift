import Foundation

public protocol IdentityCrypto: AnyObject {

    var publicKey: Data { get }
    func sign(_ message: Data) -> Data
    func verify(publicKey: Data, message: Data, signature: Data) -> Bool

    func sharedSecret(with publicKey: Data) -> Data?
}
