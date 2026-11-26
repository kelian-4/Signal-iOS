import Foundation
import CoreBluetooth
import MeshCore

public enum MeshBLEUUID {
    public static let service = CBUUID(string: "6F1C2A40-8D3E-4B7A-9C15-3E2F7A9B0D41")
    public static let rx = CBUUID(string: "6F1C2A41-8D3E-4B7A-9C15-3E2F7A9B0D41")
    public static let tx = CBUUID(string: "6F1C2A42-8D3E-4B7A-9C15-3E2F7A9B0D41")
    public static let info = CBUUID(string: "6F1C2A43-8D3E-4B7A-9C15-3E2F7A9B0D41")
}

public struct BLEPeerInfo: Equatable {
    public let id: String
    public let rssi: Int?
    public let state: String

    public init(id: String, rssi: Int?, state: String) {
        self.id = id
        self.rssi = rssi
        self.state = state
    }
}

public struct BLEStatus: Equatable {
    public var centralState = "?"
    public var peripheralState = "?"
    public var scanning = false
    public var advertising = false
    public var serverReady = false
    public var readyLinks = 0
    public var peers: [BLEPeerInfo] = []

    public init() {}
}

private func nowMs() -> Int64 { return Int64(Date().timeIntervalSince1970 * 1000) }

fileprivate protocol BLELink: AnyObject {
    var key: String { get }
    var label: String { get }
    var ready: Bool { get }
    var lastActivityMs: Int64 { get set }
    func maxFrame() -> Int
    func write(_ frame: Data)
}

fileprivate final class ClientLink: BLELink {
    let peripheral: CBPeripheral
    var rx: CBCharacteristic?
    var tx: CBCharacteristic?
    var info: CBCharacteristic?
    var ready = false
    var everReady = false
    var lastActivityMs: Int64 = nowMs()
    private var queue: [Data] = []
    private var busy = false

    init(peripheral: CBPeripheral) { self.peripheral = peripheral }

    var key: String { return peripheral.identifier.uuidString }
    var label: String { return "cli:" + String(key.prefix(8)) }

    func maxFrame() -> Int { return max(20, peripheral.maximumWriteValueLength(for: .withoutResponse)) }

    func write(_ frame: Data) {
        lastActivityMs = nowMs()
        queue.append(frame)
        pump()
    }

    private func pump() {
        guard !busy, let rx = rx, !queue.isEmpty else { return }
        let item = queue.removeFirst()
        busy = true
        peripheral.writeValue(item, for: rx, type: .withResponse)
    }

    func writeCompleted() {
        busy = false
        pump()
    }

    func reset() {
        queue.removeAll()
        busy = false
        ready = false
    }
}

fileprivate final class ServerLink: BLELink {
    let central: CBCentral
    let sender: (Data, CBCentral) -> Bool
    var lastActivityMs: Int64 = nowMs()
    private var queue: [Data] = []

    init(central: CBCentral, sender: @escaping (Data, CBCentral) -> Bool) {
        self.central = central
        self.sender = sender
    }

    var key: String { return central.identifier.uuidString }
    var label: String { return "srv:" + String(key.prefix(8)) }
    var ready: Bool { return true }

    func maxFrame() -> Int { return max(20, central.maximumUpdateValueLength) }

    func write(_ frame: Data) {
        lastActivityMs = nowMs()
        queue.append(frame)
        pump()
    }

    func pump() {
        while let first = queue.first {
            if sender(first, central) {
                queue.removeFirst()
            } else {
                break
            }
        }
    }
}

private struct PeerRec {
    var rssi: Int?
    var lastSeen: Date
}

public final class MeshBLETransport: NSObject, Transport {
    public weak var delegate: TransportDelegate?
    public let queue = DispatchQueue(label: "cm.messagerie.mesh.ble")

    public var hasPendingWork: () -> Bool = { false }

    public var onTick: (() -> Void)?

    public var onStatus: ((BLEStatus) -> Void)?
    public var logger: MeshLogger = NullLogger()
    public let restoreIdPrefix: String

    private var diagnostics: FieldDiagnostics?
    private var central: CBCentralManager!
    private var peripheralMgr: CBPeripheralManager!
    private let sessionToken: Data = Data((0..<8).map { _ in UInt8.random(in: 0...255) })

    private var clientLinks: [String: ClientLink] = [:]
    private var serverLinks: [String: ServerLink] = [:]
    private var known: [String: CBPeripheral] = [:]
    private var peerRecs: [String: PeerRec] = [:]
    private var attempts: [String: Int] = [:]
    private var nextConnectAt: [String: Date] = [:]
    private var txChar: CBMutableCharacteristic?
    private var serverReady = false
    private var advertising = false
    private var scanning = false
    private var started = false
    private var lastRssiPoll = Date.distantPast

    public init(restoreIdPrefix: String = "cm.messagerie.mesh") {
        self.restoreIdPrefix = restoreIdPrefix
        super.init()
    }

    public func start() {
        queue.async {
            guard !self.started else { return }
            self.started = true
            let diag = FieldDiagnostics(logger: self.logger, queue: self.queue)
            self.diagnostics = diag
            diag.start()
            self.central = CBCentralManager(delegate: self, queue: self.queue, options: [
                CBCentralManagerOptionRestoreIdentifierKey: self.restoreIdPrefix + ".central",
                CBCentralManagerOptionShowPowerAlertKey: true,
            ])
            self.peripheralMgr = CBPeripheralManager(delegate: self, queue: self.queue, options: [
                CBPeripheralManagerOptionRestoreIdentifierKey: self.restoreIdPrefix + ".peripheral",
            ])
            self.scheduleHousekeeping()
            self.logger.log("transport_start", ["restore_prefix": self.restoreIdPrefix])
        }
    }

    public func connectNow() {
        queue.async {
            for p in Array(self.known.values) { self.connectIfNeeded(p) }
        }
    }

    public func send(_ frame: Data, on linkId: String) -> Bool {
        guard let link = link(labeled: linkId), link.ready else { return false }
        link.write(frame)
        return true
    }

    public func reset(link linkId: String) {
        if let c = clientLinks.values.first(where: { $0.label == linkId }) {
            logger.log("watchdog_cut", ["link": linkId, "role": "client"])
            central.cancelPeripheralConnection(c.peripheral)
            if central.state == .poweredOn {
                if central.isScanning { central.stopScan() }
                scanning = false
                startScan()
            }
        } else if let s = serverLinks.values.first(where: { $0.label == linkId }) {
            logger.log("watchdog_cut", ["link": linkId, "role": "server"])
            serverLinks[s.key] = nil
            delegate?.transportDidDisconnect(link: s.label)
            restartServer()
        }
        publish()
    }

    private func link(labeled label: String) -> BLELink? {
        if let c = clientLinks.values.first(where: { $0.label == label }) { return c }
        return serverLinks.values.first(where: { $0.label == label })
    }

    private var readyLinkCount: Int {
        return clientLinks.values.filter { $0.ready }.count + serverLinks.count
    }

    private func scheduleHousekeeping() {
        queue.asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            let now = nowMs()
            let pending = self.hasPendingWork()
            for (id, l) in self.clientLinks where shouldDropIdle(ready: l.ready, pending: pending, nowMs: now, lastActivityMs: l.lastActivityMs) {
                self.logger.log("idle_disconnect", ["link": l.label, "idle_ms": String(now - l.lastActivityMs)])
                self.central.cancelPeripheralConnection(l.peripheral)
                _ = id
            }
            if Date().timeIntervalSince(self.lastRssiPoll) > 15 {
                self.lastRssiPoll = Date()
                for l in self.clientLinks.values where l.ready { l.peripheral.readRSSI() }
            }
            self.onTick?()

            if pending { for p in Array(self.known.values) { self.connectIfNeeded(p) } }
            self.publish()
            self.scheduleHousekeeping()
        }
    }

    private func publish() {
        guard let handler = onStatus else { return }
        let now = Date()
        var peers: [BLEPeerInfo] = []
        for (id, rec) in peerRecs {
            let cl = clientLinks[id]
            let linked = cl != nil || serverLinks[id] != nil
            if !linked && now.timeIntervalSince(rec.lastSeen) > 30 {
                peerRecs[id] = nil
                continue
            }
            let state: String
            if let c = cl, c.ready { state = "client" }
            else if serverLinks[id] != nil { state = "server" }
            else if cl != nil { state = "connecting" }
            else { state = "seen" }
            peers.append(BLEPeerInfo(id: String(id.prefix(8)), rssi: rec.rssi, state: state))
        }
        peers.sort { ($0.rssi ?? Int.min) > ($1.rssi ?? Int.min) }
        var st = BLEStatus()
        st.centralState = MeshBLETransport.describe(central?.state)
        st.peripheralState = MeshBLETransport.describe(peripheralMgr?.state)
        st.scanning = scanning
        st.advertising = advertising
        st.serverReady = serverReady
        st.readyLinks = readyLinkCount
        st.peers = peers
        DispatchQueue.main.async { handler(st) }
    }

    fileprivate static func describe(_ s: CBManagerState?) -> String {
        guard let s = s else { return "unknown" }
        switch s {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "off"
        case .poweredOn: return "on"
        @unknown default: return "unknown"
        }
    }

    private func touchPeer(_ id: String, rssi: Int?) {
        var rec = peerRecs[id] ?? PeerRec(rssi: nil, lastSeen: Date())
        if let r = rssi, r != 127 { rec.rssi = r }
        rec.lastSeen = Date()
        peerRecs[id] = rec
    }

    private func startScan() {
        guard central.state == .poweredOn else { return }
        if central.isScanning { scanning = true; return }
        central.scanForPeripherals(withServices: [MeshBLEUUID.service],
                                   options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        scanning = true
        logger.log("scan_start", [:])
    }

    private func connectIfNeeded(_ p: CBPeripheral) {
        let id = p.identifier.uuidString
        guard central.state == .poweredOn, clientLinks[id] == nil else { return }

        let nextMs = nextConnectAt[id].map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0
        guard shouldConnect(pending: hasPendingWork(), readyLinks: readyLinkCount, clientLinks: clientLinks.count,
                            nowMs: nowMs(), nextConnectAtMs: nextMs, ignoreUntilMs: 0,
                            inboundFromPeer: serverLinks[id] != nil) else { return }
        let link = ClientLink(peripheral: p)
        clientLinks[id] = link
        p.delegate = self
        logger.log("connect", ["link": link.label, "attempt": String((attempts[id] ?? 0) + 1)])
        central.connect(p, options: nil)
        publish()
    }

    private func closeClient(_ id: String, reason: String, error: Error?) {
        guard let link = clientLinks[id] else { return }
        let wasReady = link.ready
        link.reset()
        clientLinks[id] = nil
        let delay: TimeInterval
        if link.everReady {
            attempts[id] = nil
            delay = 2
        } else {
            let n = (attempts[id] ?? 0) + 1
            attempts[id] = n

            delay = min(30, pow(2.0, Double(min(n, 5))))
        }
        nextConnectAt[id] = Date().addingTimeInterval(delay)
        var f: [String: String] = ["link": link.label, "reason": reason, "was_ready": wasReady ? "1" : "0",
                                   "backoff_s": String(Int(delay))]
        if let e = error as NSError? { f["err_domain"] = e.domain; f["err_code"] = String(e.code) }
        if let rssi = peerRecs[id]?.rssi { f["last_rssi"] = String(rssi) }
        logger.log("link_closed", f)
        if wasReady { delegate?.transportDidDisconnect(link: link.label) }
        queue.asyncAfter(deadline: .now() + delay + 0.2) { [weak self] in
            guard let self = self, let p = self.known[id] else { return }
            self.connectIfNeeded(p)
        }
        publish()
    }

    private func setupService() {
        if txChar != nil {

            serverReady = true
            if !peripheralMgr.isAdvertising { startAdvertising() } else { advertising = true }
            return
        }
        let info = Data([1]) + sessionToken
        let rx = CBMutableCharacteristic(type: MeshBLEUUID.rx, properties: [.write], value: nil, permissions: [.writeable])
        let tx = CBMutableCharacteristic(type: MeshBLEUUID.tx, properties: [.notify], value: nil, permissions: [.readable])
        let infoChar = CBMutableCharacteristic(type: MeshBLEUUID.info, properties: [.read], value: info, permissions: [.readable])
        let svc = CBMutableService(type: MeshBLEUUID.service, primary: true)
        svc.characteristics = [rx, tx, infoChar]
        txChar = tx
        peripheralMgr.add(svc)
        logger.log("gatt_server", ["event": "add_service"])
    }

    private func startAdvertising() {

        peripheralMgr.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [MeshBLEUUID.service]])
    }

    private func restartServer() {
        guard peripheralMgr != nil, peripheralMgr.state == .poweredOn else { return }
        peripheralMgr.stopAdvertising()
        peripheralMgr.removeAllServices()
        txChar = nil
        serverReady = false
        advertising = false
        queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.peripheralMgr.state == .poweredOn else { return }
            self.setupService()
        }
    }
}

extension MeshBLETransport: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ c: CBCentralManager) {
        logger.log("central_state", ["state": MeshBLETransport.describe(c.state)])
        if c.state == .poweredOn {
            startScan()
            for p in known.values where p.state == .disconnected { connectIfNeeded(p) }
        } else {
            scanning = false
        }
        publish()
    }

    public func centralManager(_ c: CBCentralManager, willRestoreState dict: [String: Any]) {
        logger.log("central_restore", [:])
        if let ps = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            for p in ps {
                let id = p.identifier.uuidString
                p.delegate = self
                known[id] = p
                touchPeer(id, rssi: nil)
                clientLinks[id] = ClientLink(peripheral: p)
                logger.log("central_restore_peripheral", ["state": String(p.state.rawValue)])
                if p.state == .connected { p.discoverServices([MeshBLEUUID.service]) }
            }
        }
    }

    public func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral,
                               advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let id = p.identifier.uuidString
        let first = peerRecs[id] == nil
        known[id] = p
        p.delegate = self
        touchPeer(id, rssi: RSSI.intValue)
        if first {
            logger.log("discovered", ["peer": String(id.prefix(8)), "rssi": String(RSSI.intValue)])
            publish()
        }
        connectIfNeeded(p)
    }

    public func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        let id = p.identifier.uuidString
        if clientLinks[id] == nil { clientLinks[id] = ClientLink(peripheral: p) }
        p.delegate = self
        p.discoverServices([MeshBLEUUID.service])
    }

    public func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        closeClient(p.identifier.uuidString, reason: "connect_failed", error: error)
    }

    public func centralManager(_ c: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        closeClient(p.identifier.uuidString, reason: "disconnected", error: error)
    }
}

extension MeshBLETransport: CBPeripheralDelegate {
    public func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        let id = p.identifier.uuidString
        guard let svc = p.services?.first(where: { $0.uuid == MeshBLEUUID.service }), error == nil else {
            logger.log("service_discovery_failed", ["peer": String(id.prefix(8))])
            nextConnectAt[id] = Date().addingTimeInterval(60)
            central.cancelPeripheralConnection(p)
            return
        }
        p.discoverCharacteristics([MeshBLEUUID.rx, MeshBLEUUID.tx, MeshBLEUUID.info], for: svc)
    }

    public func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let id = p.identifier.uuidString
        guard let link = clientLinks[id], error == nil else {
            central.cancelPeripheralConnection(p)
            return
        }
        for c in service.characteristics ?? [] {
            if c.uuid == MeshBLEUUID.rx { link.rx = c }
            if c.uuid == MeshBLEUUID.tx { link.tx = c }
            if c.uuid == MeshBLEUUID.info { link.info = c }
        }
        guard let tx = link.tx, link.rx != nil, let info = link.info else {
            logger.log("characteristics_missing", ["peer": String(id.prefix(8))])
            nextConnectAt[id] = Date().addingTimeInterval(60)
            central.cancelPeripheralConnection(p)
            return
        }
        p.readValue(for: info)
        p.setNotifyValue(true, for: tx)
    }

    public func peripheral(_ p: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        let id = p.identifier.uuidString
        guard characteristic.uuid == MeshBLEUUID.tx, let link = clientLinks[id] else { return }
        if error != nil {
            central.cancelPeripheralConnection(p)
            return
        }
        if characteristic.isNotifying && !link.ready {
            link.ready = true
            link.everReady = true
            attempts[id] = nil
            logger.log("link_ready", ["link": link.label, "role": "client", "max_frame": String(link.maxFrame()),
                                      "rssi": peerRecs[id]?.rssi.map(String.init) ?? "?"])
            delegate?.transportDidConnect(link: link.label, maxFrameSize: link.maxFrame())
            publish()
        }
    }

    public func peripheral(_ p: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        let id = p.identifier.uuidString
        guard error == nil, let value = characteristic.value else { return }
        if characteristic.uuid == MeshBLEUUID.info {
            guard value.count >= 9, value[value.startIndex] == 1 else { return }
            let remote = value.subdata(in: (value.startIndex + 1)..<(value.startIndex + 9))
            if remote == sessionToken {
                logger.log("self_connection", ["peer": String(id.prefix(8))])
                nextConnectAt[id] = Date().addingTimeInterval(600)
                central.cancelPeripheralConnection(p)
            }
        } else if characteristic.uuid == MeshBLEUUID.tx, let link = clientLinks[id] {
            link.lastActivityMs = nowMs()
            delegate?.transportDidReceive(value, on: link.label)
        }
    }

    public func peripheral(_ p: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let id = p.identifier.uuidString
        if let e = error as NSError? {
            logger.log("write_failed", ["peer": String(id.prefix(8)), "err_domain": e.domain, "err_code": String(e.code)])
        }
        clientLinks[id]?.writeCompleted()
    }

    public func peripheral(_ p: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else { return }
        let id = p.identifier.uuidString
        touchPeer(id, rssi: RSSI.intValue)
        logger.log("rssi", ["link": "cli:" + String(id.prefix(8)), "rssi": String(RSSI.intValue)])
    }
}

extension MeshBLETransport: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ p: CBPeripheralManager) {
        logger.log("peripheral_state", ["state": MeshBLETransport.describe(p.state)])
        if p.state == .poweredOn {
            setupService()
        } else {
            advertising = false
            serverReady = false
        }
        publish()
    }

    public func peripheralManager(_ p: CBPeripheralManager, willRestoreState dict: [String: Any]) {
        logger.log("peripheral_restore", [:])
        if let services = dict[CBPeripheralManagerRestoredStateServicesKey] as? [CBMutableService] {
            for s in services where s.uuid == MeshBLEUUID.service {
                for c in s.characteristics ?? [] where c.uuid == MeshBLEUUID.tx {
                    txChar = c as? CBMutableCharacteristic
                }
            }
        }
    }

    public func peripheralManager(_ p: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            logger.log("add_service_failed", ["error": error.localizedDescription])
            txChar = nil
            return
        }
        serverReady = true
        startAdvertising()
        publish()
    }

    public func peripheralManagerDidStartAdvertising(_ p: CBPeripheralManager, error: Error?) {
        advertising = error == nil
        if let error = error { logger.log("advertising_failed", ["error": error.localizedDescription]) }
        publish()
    }

    public func peripheralManager(_ p: CBPeripheralManager, central cen: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        guard characteristic.uuid == MeshBLEUUID.tx else { return }
        let link = ServerLink(central: cen) { [weak self] data, target in
            guard let self = self, let tx = self.txChar else { return false }
            return self.peripheralMgr.updateValue(data, for: tx, onSubscribedCentrals: [target])
        }
        serverLinks[link.key] = link
        touchPeer(link.key, rssi: nil)
        logger.log("link_ready", ["link": link.label, "role": "server", "max_frame": String(link.maxFrame())])
        delegate?.transportDidConnect(link: link.label, maxFrameSize: link.maxFrame())
        publish()
    }

    public func peripheralManager(_ p: CBPeripheralManager, central cen: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        guard characteristic.uuid == MeshBLEUUID.tx else { return }
        let key = cen.identifier.uuidString
        if let l = serverLinks.removeValue(forKey: key) {
            logger.log("link_closed", ["link": l.label, "reason": "unsubscribed"])
            delegate?.transportDidDisconnect(link: l.label)
        }
        publish()
    }

    public func peripheralManagerIsReady(toUpdateSubscribers p: CBPeripheralManager) {
        for l in serverLinks.values { l.pump() }
    }

    public func peripheralManager(_ p: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for r in requests where r.characteristic.uuid == MeshBLEUUID.rx {
            guard let v = r.value, let link = serverLinks[r.central.identifier.uuidString] else { continue }
            link.lastActivityMs = nowMs()
            delegate?.transportDidReceive(v, on: link.label)
        }
        if let first = requests.first { p.respond(to: first, withResult: .success) }
    }
}
