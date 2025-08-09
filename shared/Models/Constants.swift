import Foundation

public struct Constants {
    public static let appGroup = "group.com.yourcompany.navi"
    public static let watchConnectivityKey = "NaviWatchConnectivity"
    
    public struct Notification {
        public static let categoryIdentifier = "TAP_RECEIVED"
        public static let tapAction = "TAP_ACTION"
    }
    
    public struct UserDefaults {
        public static let userId = "userId"
        public static let authToken = "authToken"
        public static let partnerId = "partnerId"
        public static let isPaired = "isPaired"
    }
}