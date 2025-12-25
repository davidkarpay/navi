import Foundation
import WatchConnectivity

/// Information about a received tap
struct TapInfo: Equatable {
    let intensity: String
    let pattern: String
    let timestamp: Date

    init(intensity: String, pattern: String) {
        self.intensity = intensity
        self.pattern = pattern
        self.timestamp = Date()
    }
}

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    // Connection state
    @Published var isReachable = false
    @Published var isPaired = false

    // App state synced from iPhone
    @Published var isAuthenticated = false
    @Published var isPairedWithPartner = false

    // Last received tap (for UI updates)
    @Published var lastReceivedTap: TapInfo?

    private var session: WCSession?

    private override init() {
        super.init()
        setupSession()
    }

    private func setupSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Send Tap to iPhone

    /// Send a tap to the partner via the iPhone
    func sendTapToPhone(intensity: String, pattern: String, completion: @escaping (Bool) -> Void) {
        guard let session = session, session.isReachable else {
            completion(false)
            return
        }

        let message: [String: Any] = [
            "type": "sendTap",
            "intensity": intensity,
            "pattern": pattern,
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                let success = reply["success"] as? Bool ?? false
                completion(success)
            }
        }) { error in
            print("Error sending tap: \(error)")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }

    // MARK: - Request State from iPhone

    /// Request current auth/pairing state from iPhone
    func requestStateFromPhone() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = ["type": "requestState"]

        session.sendMessage(message, replyHandler: { reply in
            DispatchQueue.main.async {
                self.isAuthenticated = reply["isAuthenticated"] as? Bool ?? false
                self.isPairedWithPartner = reply["isPairedWithPartner"] as? Bool ?? false
            }
        }) { error in
            print("Error requesting state: \(error)")
        }
    }

    // MARK: - Legacy method (for compatibility)

    func sendTap(type: String) {
        sendTapToPhone(intensity: "medium", pattern: type) { _ in }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            // On watchOS, the Watch is always paired to an iPhone when the app runs
            // (isPaired property is only available on iOS)
            self.isPaired = (activationState == .activated)
            self.isReachable = session.isReachable
        }

        // Request initial state when activated
        if activationState == .activated && session.isReachable {
            requestStateFromPhone()
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }

        // Request state when iPhone becomes reachable
        if session.isReachable {
            requestStateFromPhone()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let type = message["type"] as? String else { return }

        DispatchQueue.main.async {
            switch type {
            case "tap":
                // Incoming tap from partner (forwarded by iPhone)
                let intensity = message["intensity"] as? String ?? "medium"
                let pattern = message["pattern"] as? String ?? "single"
                self.lastReceivedTap = TapInfo(intensity: intensity, pattern: pattern)
                HapticManager.shared.playTapReceivedHaptic()

            case "stateUpdate":
                // State update from iPhone
                self.isAuthenticated = message["isAuthenticated"] as? Bool ?? false
                self.isPairedWithPartner = message["isPairedWithPartner"] as? Bool ?? false

            default:
                break
            }
        }
    }
}