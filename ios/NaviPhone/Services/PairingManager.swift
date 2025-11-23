import Foundation
import SwiftUI
import NaviShared

class PairingManager: ObservableObject {
    @Published var isPaired = false
    @Published var partnerId: String?
    @Published var pairedAt: Date?

    private let baseURL = Constants.backendURL
    private var authToken: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    init() {
        checkPairingStatus()
        connectWebSocket()
    }
    
    func checkPairingStatus() {
        Task {
            await fetchPairingStatus()
        }
    }
    
    private func fetchPairingStatus() async {
        guard let authToken = authToken else { return }
        
        do {
            let url = URL(string: "\(baseURL)/api/pairing/status")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let status = try JSONDecoder().decode(PairingStatus.self, from: data)
            
            await MainActor.run {
                self.isPaired = status.paired
                self.partnerId = status.partnerId
                if let pairedAtString = status.pairedAt {
                    self.pairedAt = ISO8601DateFormatter().date(from: pairedAtString)
                }
            }
        } catch {
            print("Pairing status error: \(error)")
        }
    }
    
    func createPairingCode() async -> String? {
        guard let authToken = authToken else { return nil }
        
        do {
            let url = URL(string: "\(baseURL)/api/pairing/create")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(PairingCodeResponse.self, from: data)
            
            return response.pairingCode
        } catch {
            print("Create pairing code error: \(error)")
            return nil
        }
    }
    
    func joinWithCode(_ code: String) async -> Bool {
        guard let authToken = authToken else { return false }
        
        do {
            let url = URL(string: "\(baseURL)/api/pairing/join")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = ["pairingCode": code]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(JoinResponse.self, from: data)
            
            await MainActor.run {
                self.isPaired = true
                self.partnerId = response.partnerId
                self.pairedAt = Date()
            }
            
            return true
        } catch {
            print("Join pairing error: \(error)")
            return false
        }
    }
    
    func unpair() async {
        guard let authToken = authToken else { return }
        
        do {
            let url = URL(string: "\(baseURL)/api/pairing/unpair")!
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            let (_, _) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                self.isPaired = false
                self.partnerId = nil
                self.pairedAt = nil
            }
        } catch {
            print("Unpair error: \(error)")
        }
    }
    
    private func connectWebSocket() {
        guard let authToken = authToken else { return }
        
        var urlComponents = URLComponents(string: baseURL)!
        urlComponents.scheme = urlComponents.scheme == "https" ? "wss" : "ws"
        
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: urlComponents.url!)
        webSocketTask?.resume()
        
        // Send authentication message
        let authMessage = ["type": "auth", "token": authToken]
        if let authData = try? JSONSerialization.data(withJSONObject: authMessage),
           let authString = String(data: authData, encoding: .utf8) {
            webSocketTask?.send(.string(authString)) { error in
                if let error = error {
                    print("Auth message send error: \(error)")
                }
            }
        }
        
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleWebSocketMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleWebSocketMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
            case .failure(let error):
                print("WebSocket error: \(error)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.connectWebSocket()
                }
            }
        }
    }
    
    private func handleWebSocketMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        // Try to decode as WebSocketMessage first
        if let message = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
            DispatchQueue.main.async {
                switch message.type {
                case "auth_success":
                    print("WebSocket authenticated successfully")
                case "paired":
                    self.isPaired = true
                    self.checkPairingStatus()
                case "unpaired":
                    self.isPaired = false
                    self.partnerId = nil
                    self.pairedAt = nil
                case "tap_received":
                    // Handle as tap message - decode as TapMessage
                    if let tapMessage = try? JSONDecoder().decode(TapMessage.self, from: data) {
                        NotificationCenter.default.post(name: .tapReceived, object: tapMessage)
                    }
                default:
                    break
                }
            }
        }
    }
}

struct PairingStatus: Codable {
    let paired: Bool
    let partnerId: String?
    let pairedAt: String?
}

struct PairingCodeResponse: Codable {
    let pairingCode: String
    let expiresIn: Int
}

struct JoinResponse: Codable {
    let message: String
    let partnerId: String
}

struct WebSocketMessage: Codable {
    let type: String
    let timestamp: String?
    let message: String?
}

// Notification extension
extension Notification.Name {
    static let tapReceived = Notification.Name("tapReceived")
}