import Foundation
import WatchConnectivity
import Combine
import os.log

private let logger = Logger(subsystem: "com.navi.app", category: "WatchConnectivity")

/// Service that handles communication with the paired Apple Watch
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published var isWatchReachable = false
    @Published var isWatchPaired = false

    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()

    // References to main app managers
    private weak var authManager: AuthManager?
    private weak var pairingManager: PairingManager?
    private weak var tapManager: TapManager?

    private override init() {
        super.init()
        // Activate WCSession immediately on init
        activateSession()
    }

    /// Activate the WatchConnectivity session as early as possible
    private func activateSession() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            logger.info("Session activation requested")
        } else {
            logger.warning("WCSession not supported on this device")
        }
    }

    /// Configure the service with references to the main app managers
    func configure(auth: AuthManager, pairing: PairingManager, tap: TapManager) {
        self.authManager = auth
        self.pairingManager = pairing
        self.tapManager = tap
        logger.info("Configured with managers")

        // Observe auth changes
        auth.$isAuthenticated
            .dropFirst()
            .sink { [weak self] _ in
                self?.sendStateToWatch()
            }
            .store(in: &cancellables)

        // Observe pairing changes
        pairing.$isPaired
            .dropFirst()
            .sink { [weak self] _ in
                self?.sendStateToWatch()
            }
            .store(in: &cancellables)

        // Observe incoming taps to forward to Watch
        NotificationCenter.default.publisher(for: .tapReceived)
            .compactMap { $0.object as? TapMessage }
            .sink { [weak self] tap in
                self?.forwardTapToWatch(intensity: tap.intensity, pattern: tap.pattern)
            }
            .store(in: &cancellables)
    }

    // MARK: - Send State to Watch

    /// Send current auth/pairing state to Watch
    func sendStateToWatch() {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "type": "stateUpdate",
            "isAuthenticated": authManager?.isAuthenticated ?? false,
            "isPairedWithPartner": pairingManager?.isPaired ?? false
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending state to watch: \(error)")
        }
    }

    // MARK: - Forward Tap to Watch

    /// Forward an incoming tap from partner to Watch for haptic feedback
    func forwardTapToWatch(intensity: String, pattern: String) {
        guard let session = session, session.isReachable else { return }

        let message: [String: Any] = [
            "type": "tap",
            "intensity": intensity,
            "pattern": pattern
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Error forwarding tap to watch: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logger.info("Activation completed: state=\(activationState.rawValue), isPaired=\(session.isPaired), isReachable=\(session.isReachable), error=\(String(describing: error))")

        DispatchQueue.main.async {
            self.isWatchPaired = session.isPaired
            self.isWatchReachable = session.isReachable
        }

        if activationState == .activated {
            sendStateToWatch()
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.info("Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.info("Session deactivated, reactivating...")
        session.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.info("Reachability changed: isReachable=\(session.isReachable)")

        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }

        if session.isReachable {
            sendStateToWatch()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let type = message["type"] as? String else {
            replyHandler(["success": false, "error": "Unknown message type"])
            return
        }

        switch type {
        case "requestState":
            // Watch is requesting current state
            replyHandler([
                "isAuthenticated": authManager?.isAuthenticated ?? false,
                "isPairedWithPartner": pairingManager?.isPaired ?? false
            ])

        case "sendTap":
            // Watch wants to send a tap to partner
            let intensity = message["intensity"] as? String ?? "medium"
            let pattern = message["pattern"] as? String ?? "single"

            Task {
                let success = await tapManager?.sendTap(intensity: intensity, pattern: pattern) ?? false
                replyHandler(["success": success])
            }

        default:
            replyHandler(["success": false, "error": "Unhandled message type: \(type)"])
        }
    }

    // Handle messages without reply handler
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Forward to the reply handler version with a no-op reply
        self.session(session, didReceiveMessage: message) { _ in }
    }
}
