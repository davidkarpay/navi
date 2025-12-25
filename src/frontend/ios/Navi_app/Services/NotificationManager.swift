import Foundation
import UserNotifications
import UIKit

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    var deviceToken: String?
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func setDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        
        Task {
            if let authManager = await getAuthManager() {
                await authManager.updateDeviceToken(token)
            }
        }
    }
    
    func getDeviceToken() async -> String? {
        if let token = deviceToken {
            return token
        }
        
        // Wait for token if not available yet
        for _ in 0..<10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            if let token = deviceToken {
                return token
            }
        }
        
        return nil
    }
    
    private func getAuthManager() async -> AuthManager? {
        // This is a workaround to access AuthManager from AppDelegate
        // In production, you'd use dependency injection
        return nil
    }
}