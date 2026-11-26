import Foundation
public import LibSignalClient

public final class MeshChatConnectionManager: ChatConnectionManager {
    public var onRegistrationStateChange: ((_ isDelinkedOrDeregisterd: Bool, _ tx: DBWriteTransaction) -> Void)?

    private let messages = MeshMessagesService()

    public init() {}

    public func updateCanOpenWebSocket() {}

    public func waitForIdentifiedConnectionToOpen() async throws(CancellationError) {}

    public func waitForUnidentifiedConnectionToOpen() async throws(CancellationError) {}

    public func waitUntilIdentifiedConnectionShouldBeClosed() async throws(CancellationError) {
        do {
            while true {
                try await Task.sleep(nanoseconds: 3_600_000_000_000)
            }
        } catch {
            throw CancellationError()
        }
    }

    @MainActor
    public var unidentifiedConnectionState: OWSChatConnectionState { return .open }

    public var hasDirectConnection: Bool {
        get async { return true }
    }

    public var hasEmptiedInitialQueue: Bool {
        get async { return true }
    }

    public func requestIdentifiedConnection() -> OWSChatConnection.ConnectionToken {
        return OWSChatConnection.ConnectionToken(tokenId: 0, chatConnection: nil)
    }

    public func requestUnidentifiedConnection() -> OWSChatConnection.ConnectionToken {
        return OWSChatConnection.ConnectionToken(tokenId: 0, chatConnection: nil)
    }

    public func waitForDisconnectIfClosed() async {}

    public func setRegistrationOverride(_ chatServiceAuth: ChatServiceAuth) async {}

    public func clearRegistrationOverride() async {}

    public func keyTransparencyClient() async throws -> KeyTransparency.Client {
        throw OWSHTTPError.networkFailure(.genericFailure)
    }

    public func makeRequest(_ request: TSRequest) async throws -> HTTPResponse {
        return try MeshRequestRouter.handle(request)
    }

    public func withUnauthServiceImpl<Service, Output>(
        _ service: Service,
        do callback: (Service.Api) async throws -> Output,
    ) async throws -> Output where Service: UnauthServiceSelector {
        if let api = messages as? Service.Api {
            return try await callback(api)
        }
        throw OWSHTTPError.networkFailure(.genericFailure)
    }

    public func withAuthServiceImpl<Service, Output>(
        _ service: Service,
        do callback: (Service.Api) async throws -> Output,
    ) async throws -> Output where Service: AuthServiceSelector {
        if let api = messages as? Service.Api {
            return try await callback(api)
        }
        throw OWSHTTPError.networkFailure(.genericFailure)
    }
}

enum MeshRequestRouter {
    static func handle(_ request: TSRequest) throws -> HTTPResponse {
        let path = request.url.path.hasPrefix("/") ? String(request.url.path.dropFirst()) : request.url.path
        let components = path.split(separator: "/").map(String.init)

        if components.count == 3, components[0] == "v2", components[1] == "keys", request.method == "GET" {
            guard
                let serviceId = try? ServiceId.parseFrom(serviceIdString: components[2]),
                let aci = serviceId as? Aci,
                let json = MeshBackendRegistry.shared.backend?.meshPreKeyBundleJSON(for: aci)
            else {
                return HTTPResponse(requestUrl: request.url, status: 404)
            }
            return HTTPResponse(requestUrl: request.url, status: 200, bodyData: json)
        }

        if components.count == 4, components[0] == "v2", components[1] == "keys", request.method == "GET" {
            guard
                let serviceId = try? ServiceId.parseFrom(serviceIdString: components[2]),
                let aci = serviceId as? Aci,
                let json = MeshBackendRegistry.shared.backend?.meshPreKeyBundleJSON(for: aci)
            else {
                return HTTPResponse(requestUrl: request.url, status: 404)
            }
            return HTTPResponse(requestUrl: request.url, status: 200, bodyData: json)
        }

        if components == ["v2", "keys"] {
            if request.method == "GET" {
                let body = Data("{\"count\":100,\"pqCount\":100}".utf8)
                return HTTPResponse(requestUrl: request.url, status: 200, bodyData: body)
            }
            if request.method == "PUT" {
                if let json = encodedBody(of: request) {
                    let identity: OWSIdentity = (request.url.query ?? "").contains("identity=pni") ? .pni : .aci
                    if identity == .aci {
                        MeshPreKeyStore.shared.merge(uploadJSON: json)
                    }
                    MeshBackendRegistry.shared.backend?.meshDidUploadPreKeys(json: json, identity: identity)
                }
                return HTTPResponse(requestUrl: request.url, status: 204)
            }
        }

        throw OWSHTTPError.networkFailure(.genericFailure)
    }

    private static func encodedBody(of request: TSRequest) -> Data? {
        switch request.body {
        case .data(let data):
            return data
        case .encodable(let value):
            return try? JSONEncoder().encode(AnyEncodable(value))
        case .parameters(let params):
            return try? TSRequest.Body.encodedParameters(params)
        }
    }
}

private struct AnyEncodable: Encodable {
    let value: any Encodable

    init(_ value: any Encodable) {
        self.value = value
    }

    func encode(to encoder: any Encoder) throws {
        try value.encode(to: encoder)
    }
}

final class MeshMessagesService: AuthMessagesService, UnauthMessagesService {
    func getUploadForm(uploadSize: UInt64) async throws -> UploadForm {
        throw OWSHTTPError.networkFailure(.genericFailure)
    }

    func sendMessage(
        to recipient: ServiceId,
        timestamp: UInt64,
        contents: [SingleOutboundUnsealedMessage],
        onlineOnly: Bool,
        urgent: Bool,
    ) async throws {
        guard let backend = MeshBackendRegistry.shared.backend else {
            throw OWSHTTPError.networkFailure(.genericFailure)
        }
        let messages = contents.map {
            MeshOutboundMessage(
                deviceId: $0.deviceId.uint32Value,
                registrationId: $0.registrationId,
                envelopeType: MeshIdentity.envelopeType(forCiphertextType: $0.contents.messageType),
                content: $0.contents.serialize(),
            )
        }
        try await backend.meshSend(to: recipient, timestamp: timestamp, messages: messages, urgent: urgent)
    }

    func sendSyncMessage(
        timestamp: UInt64,
        contents: [SingleOutboundUnsealedMessage],
        urgent: Bool,
    ) async throws {}

    func reportMessage(_ messageGuid: UUID, from source: Aci, spamToken: Data) async throws {}

    func sendMultiRecipientMessage(
        _ payload: Data,
        timestamp: UInt64,
        auth: MultiRecipientSendAuth,
        onlineOnly: Bool,
        urgent: Bool,
    ) async throws -> MultiRecipientMessageResponse {
        throw OWSHTTPError.networkFailure(.genericFailure)
    }

    func sendMessage(
        to recipient: ServiceId,
        timestamp: UInt64,
        contents: [SingleOutboundSealedSenderMessage],
        auth: UserBasedSendAuth,
        onlineOnly: Bool,
        urgent: Bool,
    ) async throws {
        throw SignalError.requestUnauthorized("sealed sender is not available offline")
    }
}
