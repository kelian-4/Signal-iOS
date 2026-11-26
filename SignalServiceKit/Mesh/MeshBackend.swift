import CryptoKit
import Foundation
public import LibSignalClient

public struct MeshOutboundMessage {
    public let deviceId: UInt32
    public let registrationId: UInt32
    public let envelopeType: Int32
    public let content: Data

    public init(deviceId: UInt32, registrationId: UInt32, envelopeType: Int32, content: Data) {
        self.deviceId = deviceId
        self.registrationId = registrationId
        self.envelopeType = envelopeType
        self.content = content
    }
}

public protocol MeshBackend: AnyObject {
    func meshSend(to recipient: ServiceId, timestamp: UInt64, messages: [MeshOutboundMessage], urgent: Bool) async throws
    func meshPreKeyBundleJSON(for aci: Aci) -> Data?
    func meshDidUploadPreKeys(json: Data, identity: OWSIdentity)
}

public final class MeshBackendRegistry: @unchecked Sendable {
    public static let shared = MeshBackendRegistry()

    private let lock = NSLock()
    private var current: MeshBackend?

    public var backend: MeshBackend? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return current
        }
        set {
            lock.lock()
            current = newValue
            lock.unlock()
        }
    }
}

public enum MeshIdentity {
    public static func aci(forIdentityKey identityKey: Data) -> Aci {
        var bytes = [UInt8](SHA256.hash(data: identityKey).prefix(16))
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        let uuid = UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
        ))
        return Aci(fromUUID: uuid)
    }

    public static func envelopeType(forCiphertextType type: CiphertextMessage.MessageType) -> Int32 {
        if type == .preKey { return SSKProtoEnvelopeType.prekeyBundle.rawValue }
        if type == .plaintext { return SSKProtoEnvelopeType.plaintextContent.rawValue }
        return SSKProtoEnvelopeType.ciphertext.rawValue
    }
}

public enum MeshInbox {
    public static func deliver(
        senderAci: Aci,
        senderDeviceId: UInt32,
        destination: ServiceId,
        envelopeType: Int32,
        content: Data,
        timestamp: UInt64,
    ) {
        let now = Date.ows_millisecondTimestamp()
        let builder = SSKProtoEnvelope.builder(timestamp: timestamp)
        builder.setType(SSKProtoEnvelopeType(rawValue: envelopeType) ?? .ciphertext)
        builder.setSourceServiceID(senderAci.serviceIdString)
        builder.setSourceDevice(senderDeviceId)
        builder.setDestinationServiceID(destination.serviceIdString)
        builder.setContent(content)
        builder.setServerTimestamp(now)
        builder.setServerGuid(UUID().uuidString)
        builder.setUrgent(true)
        guard let data = try? builder.buildSerializedData() else {
            Logger.warn("Mesh envelope could not be serialized")
            return
        }
        SSKEnvironment.shared.messageProcessorRef.enqueueReceivedEnvelopeData(
            data,
            serverDeliveryTimestamp: now,
            envelopeSource: .websocketIdentified,
            completion: {},
        )
    }
}

public final class MeshPreKeyStore: @unchecked Sendable {
    public static let shared = MeshPreKeyStore()

    private let lock = NSLock()
    private var aciState: [String: Any] = [:]

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base.appendingPathComponent("mesh-prekeys.json")
    }

    private init() {
        if let data = try? Data(contentsOf: fileURL),
           let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            aciState = obj
        }
    }

    public func merge(uploadJSON: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: uploadJSON) as? [String: Any] else { return }
        lock.lock()
        defer { lock.unlock() }
        for key in ["signedPreKey", "pqLastResortPreKey"] {
            if let v = obj[key] { aciState[key] = v }
        }
        for key in ["preKeys", "pqPreKeys"] {
            if let v = obj[key] as? [[String: Any]], !v.isEmpty { aciState[key] = v }
        }
        if let out = try? JSONSerialization.data(withJSONObject: aciState) {
            try? out.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        }
    }

    public func bundleJSON(identityKey: Data, registrationId: UInt32) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        guard let signed = aciState["signedPreKey"] else { return nil }
        let pq: Any? = (aciState["pqPreKeys"] as? [[String: Any]])?.first ?? aciState["pqLastResortPreKey"]
        guard let pqKey = pq else { return nil }
        var device: [String: Any] = [
            "deviceId": 1,
            "registrationId": registrationId,
            "signedPreKey": signed,
            "pqPreKey": pqKey,
        ]
        if let one = (aciState["preKeys"] as? [[String: Any]])?.first { device["preKey"] = one }
        let bundle: [String: Any] = [
            "identityKey": identityKey.base64EncodedStringWithoutPadding(),
            "devices": [device],
        ]
        return try? JSONSerialization.data(withJSONObject: bundle)
    }
}
