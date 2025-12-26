import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize WatchConnectivity early
        _ = WatchConnectivityService.shared

        // Request notification authorization on launch
        NotificationManager.shared.requestAuthorization()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Convert token to string and store it
        NotificationManager.shared.setDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error)")
        // Use mock token for simulator/development
        NotificationManager.shared.deviceToken = "simulator_\(UUID().uuidString)"
    }
}
