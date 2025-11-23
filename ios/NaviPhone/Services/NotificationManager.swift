import Foundation
import UserNotifications
import UIKit
import NaviShared

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    private var deviceToken: String?
    
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

    func updateDeviceToken(_ token: String) async {
        self.deviceToken = token

        // Send to backend if authenticated
        if let userId = UserDefaults.standard.string(forKey: Constants.UserDefaults.userId),
           let authToken = UserDefaults.standard.string(forKey: Constants.UserDefaults.authToken) {

            let baseURL = Constants.backendURL
            guard let url = URL(string: "\(baseURL)/api/auth/device-token") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let body = ["deviceToken": token]
            request.httpBody = try? JSONEncoder().encode(body)

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("Device token updated successfully")
                }
            } catch {
                print("Failed to update device token: \(error)")
            }
        }
    }

    private func getAuthManager() async -> AuthManager? {
        // This is a workaround to access AuthManager from AppDelegate
        // In production, you'd use dependency injection
        return nil
    }
}