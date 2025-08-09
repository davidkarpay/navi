import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    @Published var isPaired = false
    
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
    
    func sendTap(type: String) {
        guard let session = session, session.isReachable else { return }
        
        let message: [String: Any] = [
            "type": "tap",
            "tapType": type,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Error sending tap: \(error)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPaired = session.isPaired
            self.isReachable = session.isReachable
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle received messages
        if let type = message["type"] as? String, type == "tap" {
            HapticManager.shared.playTapReceivedHaptic()
        }
    }
}