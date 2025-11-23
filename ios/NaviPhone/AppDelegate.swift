import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register for remote notifications
        application.registerForRemoteNotifications()

        return true
    }

    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(token)")

        // Update NotificationManager with token
        Task {
            await NotificationManager.shared.updateDeviceToken(token)
        }
    }

    func application(_ application: UIApplication,
                    didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    func application(_ application: UIApplication,
                    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        // Handle remote notification
        if let tapData = userInfo["data"] as? [String: Any],
           let fromUserId = tapData["fromUserId"] as? String,
           let intensity = tapData["intensity"] as? String,
           let pattern = tapData["pattern"] as? String {

            // Trigger haptic and update UI
            Task {
                await TapManager.shared.handleIncomingTap(
                    fromUserId: fromUserId,
                    intensity: intensity,
                    pattern: pattern
                )
            }

            completionHandler(.newData)
        } else {
            completionHandler(.noData)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap
        let userInfo = response.notification.request.content.userInfo

        if let tapData = userInfo["data"] as? [String: Any] {
            // Navigate to appropriate screen or update state
            print("User tapped notification: \(tapData)")
        }

        completionHandler()
    }
}
