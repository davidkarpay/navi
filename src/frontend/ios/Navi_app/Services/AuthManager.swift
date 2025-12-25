import Foundation
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userId: String?
    @Published var authToken: String?
    
    var baseURL: String {
        return ProcessInfo.processInfo.environment["API_URL"] ?? "https://navi-production-97dd.up.railway.app"
    }
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadStoredAuth()
    }
    
    private func loadStoredAuth() {
        if let userId = userDefaults.string(forKey: "userId"),
           let authToken = userDefaults.string(forKey: "authToken") {
            self.userId = userId
            self.authToken = authToken
            self.isAuthenticated = true
        }
    }
    
    func registerAnonymousUser() async {
        guard let deviceToken = await NotificationManager.shared.getDeviceToken() else {
            print("Failed to get device token")
            return
        }
        
        do {
            let url = URL(string: "\(baseURL)/api/auth/register")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["deviceToken": deviceToken]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(AuthResponse.self, from: data)
            
            await MainActor.run {
                self.userId = response.userId
                self.authToken = response.token
                self.isAuthenticated = true
                
                userDefaults.set(response.userId, forKey: "userId")
                userDefaults.set(response.token, forKey: "authToken")
            }
        } catch {
            print("Registration error: \(error)")
        }
    }
    
    func updateDeviceToken(_ token: String) async {
        guard let userId = userId else { return }
        
        do {
            let url = URL(string: "\(baseURL)/api/auth/device-token")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(authToken ?? "")", forHTTPHeaderField: "Authorization")
            
            let body = ["userId": userId, "deviceToken": token]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, _) = try await URLSession.shared.data(for: request)
        } catch {
            print("Device token update error: \(error)")
        }
    }
    
    func clearAuthData() {
        userId = nil
        authToken = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: "userId")
        userDefaults.removeObject(forKey: "authToken")
    }
    
    func logout() {
        clearAuthData()
    }
}

struct AuthResponse: Codable {
    let userId: String
    let token: String
    let message: String
}