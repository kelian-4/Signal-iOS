import Foundation
import MeshCore
#if canImport(UIKit)
import UIKit
#endif

public final class FieldDiagnostics {
    private let logger: MeshLogger
    private let queue: DispatchQueue
    private var observers: [NSObjectProtocol] = []
    private var watchdog: DispatchSourceTimer?
    private var mainTicker: Timer?
    private let tickLock = NSLock()
    private var lastMainTickMs: Int64 = 0
    private var stallOpen = false
    private var started = false

    public init(logger: MeshLogger, queue: DispatchQueue) {
        self.logger = logger
        self.queue = queue
    }

    private func nowMs() -> Int64 { return Int64(Date().timeIntervalSince1970 * 1000) }

    private func setTick(_ v: Int64) { tickLock.lock(); lastMainTickMs = v; tickLock.unlock() }
    private func getTick() -> Int64 { tickLock.lock(); defer { tickLock.unlock() }; return lastMainTickMs }

    private static func thermalName(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal: return "nominal"
        case .fair: return "fair"
        case .serious: return "serious"
        case .critical: return "critical"
        @unknown default: return "unknown"
        }
    }

    public func snapshot(reason: String) {
        var f: [String: String] = ["reason": reason, "thermal": FieldDiagnostics.thermalName(ProcessInfo.processInfo.thermalState),
                                   "low_power": ProcessInfo.processInfo.isLowPowerModeEnabled ? "1" : "0"]
        #if canImport(UIKit) && !os(macOS)
        let level = UIDevice.current.batteryLevel
        f["battery_pct"] = level < 0 ? "?" : String(Int(level * 100))
        switch UIDevice.current.batteryState {
        case .charging: f["charging"] = "1"
        case .full: f["charging"] = "full"
        case .unplugged: f["charging"] = "0"
        default: f["charging"] = "?"
        }
        #endif
        logger.log("diag", f)
    }

    public func start() {
        guard !started else { return }
        started = true
        setTick(nowMs())
        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.snapshot(reason: "thermal_change")
        })
        observers.append(nc.addObserver(forName: Notification.Name.NSProcessInfoPowerStateDidChange, object: nil, queue: nil) { [weak self] _ in
            self?.snapshot(reason: "power_mode_change")
        })
        #if canImport(UIKit) && !os(macOS)
        DispatchQueue.main.async {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        let pairs: [(Notification.Name, String)] = [
            (UIDevice.batteryLevelDidChangeNotification, "battery_level"),
            (UIDevice.batteryStateDidChangeNotification, "battery_state"),
            (UIApplication.didBecomeActiveNotification, "app_active"),
            (UIApplication.willResignActiveNotification, "app_inactive"),
            (UIApplication.didEnterBackgroundNotification, "app_background"),
            (UIApplication.willEnterForegroundNotification, "app_foreground"),
            (UIApplication.protectedDataDidBecomeAvailableNotification, "screen_unlocked"),
            (UIApplication.protectedDataWillBecomeUnavailableNotification, "screen_locking"),
            (UIApplication.didReceiveMemoryWarningNotification, "memory_warning"),
        ]
        for (name, label) in pairs {
            observers.append(nc.addObserver(forName: name, object: nil, queue: nil) { [weak self] _ in
                if label == "battery_level" { return }
                self?.snapshot(reason: label)
            })
        }
        #endif

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                let now = self.nowMs()
                let gap = now - self.getTick()
                self.setTick(now)
                if gap > 2_000 { self.logger.log("main_thread_stall_end", ["blocked_ms": String(gap)]) }
            }
            RunLoop.main.add(t, forMode: .common)
            self.mainTicker = t
        }
        let timer = DispatchSource.makeTimerSource(queue: queue)
        var counter = 0
        timer.schedule(deadline: .now() + 1, repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let gap = self.nowMs() - self.getTick()
            if gap > 2_000 && !self.stallOpen {
                self.stallOpen = true
                self.logger.log("main_thread_stall", ["blocked_ms": String(gap)])
            } else if gap <= 2_000 {
                self.stallOpen = false
            }
            counter += 1
            if counter % 60 == 0 { self.snapshot(reason: "periodic") }
        }
        watchdog = timer
        timer.resume()
        snapshot(reason: "start")
    }

    public func stop() {
        watchdog?.cancel()
        watchdog = nil
        DispatchQueue.main.async { [weak self] in
            self?.mainTicker?.invalidate()
            self?.mainTicker = nil
        }
        for o in observers { NotificationCenter.default.removeObserver(o) }
        observers.removeAll()
        started = false
    }
}
