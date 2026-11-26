import Foundation
public import LibSignalClient

public enum MeshSignalContacts {
    public static func ensureContact(aci: Aci, displayName: String, identityKey: Data, verified: Bool) async {
        let bridge = DependenciesBridge.shared
        let keyBytes = identityKey.count == 33 ? Data(identityKey.dropFirst()) : identityKey
        await SSKEnvironment.shared.databaseStorageRef.awaitableWrite { tx in
            var recipient = bridge.recipientFetcher.fetchOrCreate(serviceId: aci, tx: tx)
            bridge.recipientManager.markAsRegisteredAndSave(
                &recipient,
                shouldUpdateStorageService: false,
                tx: tx,
            )
            let address = SignalServiceAddress(serviceId: aci, phoneNumber: nil)
            _ = bridge.identityManager.saveIdentityKey(
                keyBytes,
                for: aci,
                shouldUpdateStorageService: false,
                tx: tx,
            )
            _ = TSContactThread.getOrCreateThread(withContactAddress: address, transaction: tx)
            bridge.nicknameManager.createOrUpdate(
                nicknameRecord: NicknameRecord(recipient: recipient, givenName: displayName, familyName: nil, note: nil),
                updateStorageServiceFor: nil,
                tx: tx,
            )
            if verified {
                _ = bridge.identityManager.setVerificationState(
                    .verified,
                    of: keyBytes,
                    for: address,
                    isUserInitiatedChange: false,
                    tx: tx,
                )
            }
        }
    }

    public static func thread(for aci: Aci) -> TSContactThread {
        return TSContactThread.getOrCreateThread(
            contactAddress: SignalServiceAddress(serviceId: aci, phoneNumber: nil),
        )
    }
}
