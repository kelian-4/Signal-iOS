import Foundation

public protocol SessionCrypto: AnyObject {

    func makeBundle() throws -> Data

    func startSession(contactId: String, remoteIdentity: Data, bundle: Data) throws
    func hasSession(contactId: String) -> Bool
    func encrypt(_ plaintext: Data, for contactId: String) throws -> Data
    func decrypt(_ ciphertext: Data, from contactId: String, remoteIdentity: Data) throws -> Data

    func resetAllSessions()
}
