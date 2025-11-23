import Foundation
import SwiftUI
import NaviShared

class TapManager: ObservableObject {
    @Published var recentTaps: [TapMessage] = []

    private let baseURL = Constants.backendURL
    private var authToken: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }
    
    func sendTap(intensity: String = "medium", pattern: String = "single") async -> Bool {
        guard let authToken = authToken else { return false }
        
        do {
            let url = URL(string: "\(baseURL)/api/tap/send")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body = [
                "intensity": intensity,
                "pattern": pattern
            ]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TapResponse.self, from: data)
            
            print("Tap sent successfully: \(response.message)")
            return true
        } catch {
            print("Send tap error: \(error)")
            return false
        }
    }
    
    func fetchTapHistory() async {
        guard let authToken = authToken else { return }
        
        do {
            let url = URL(string: "\(baseURL)/api/tap/history")!
            var request = URLRequest(url: url)
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(TapHistoryResponse.self, from: data)
            
            await MainActor.run {
                self.recentTaps = response.taps
            }
        } catch {
            print("Fetch tap history error: \(error)")
        }
    }
    
    func handleIncomingTap(_ tapMessage: TapMessage) {
        Task { @MainActor in
            recentTaps.insert(tapMessage, at: 0)
            // Trigger haptic feedback
            await triggerHapticFeedback(intensity: tapMessage.intensity, pattern: tapMessage.pattern)
        }
    }
    
    @MainActor
    private func triggerHapticFeedback(intensity: String, pattern: String) async {
        let impactFeedback: UIImpactFeedbackGenerator
        
        switch intensity {
        case "light":
            impactFeedback = UIImpactFeedbackGenerator(style: .light)
        case "strong":
            impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        default:
            impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        }
        
        switch pattern {
        case "double":
            impactFeedback.impactOccurred()
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            impactFeedback.impactOccurred()
        case "triple":
            impactFeedback.impactOccurred()
            try? await Task.sleep(nanoseconds: 200_000_000)
            impactFeedback.impactOccurred()
            try? await Task.sleep(nanoseconds: 200_000_000)
            impactFeedback.impactOccurred()
        case "heartbeat":
            impactFeedback.impactOccurred()
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            impactFeedback.impactOccurred()
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            impactFeedback.impactOccurred()
            try? await Task.sleep(nanoseconds: 100_000_000)
            impactFeedback.impactOccurred()
        default: // single
            impactFeedback.impactOccurred()
        }
    }
}

struct TapResponse: Codable {
    let message: String
    let delivered: Bool
    let tapId: String
    let sentAt: String
}

struct TapHistoryResponse: Codable {
    let taps: [TapMessage]
    let count: Int
}