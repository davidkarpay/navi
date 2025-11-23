import Foundation

public struct Constants {
    // MARK: - App Configuration

    /// App Group identifier for sharing data between iOS and watchOS
    public static let appGroup = "group.Rosenbaum.Navi-app"

    /// WatchConnectivity session identifier
    public static let watchConnectivityKey = "NaviWatchConnectivity"

    // MARK: - Backend Configuration

    /// Backend API base URL - supports environment override via API_URL
    public static let backendURL: String = {
        if let envURL = ProcessInfo.processInfo.environment["API_URL"] {
            return envURL
        }

        #if DEBUG
        // Local development
        return "http://localhost:3000"
        #else
        // Production
        return "https://lovely-vibrancy-production-2c30.up.railway.app"
        #endif
    }()

    /// WebSocket URL derived from backend URL
    public static let websocketURL: String = {
        return backendURL
            .replacingOccurrences(of: "https://", with: "wss://")
            .replacingOccurrences(of: "http://", with: "ws://")
    }()

    // MARK: - Notifications

    public struct Notification {
        public static let categoryIdentifier = "TAP_RECEIVED"
        public static let tapAction = "TAP_ACTION"
    }

    // MARK: - UserDefaults Keys

    public struct UserDefaults {
        public static let userId = "userId"
        public static let authToken = "authToken"
        public static let partnerId = "partnerId"
        public static let isPaired = "isPaired"
    }
}