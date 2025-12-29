import Foundation
import SwiftUI
import Combine
import os.log

private let tapLogger = Logger(subsystem: "com.navi.app", category: "TapManager")

class TapManager: ObservableObject {
    @Published var recentTaps: [TapMessage] = []

    private var cancellables = Set<AnyCancellable>()
    private var baseURL: String {
        #if targetEnvironment(simulator)
        return ProcessInfo.processInfo.environment["API_URL"] ?? "http://localhost:3000"
        #else
        return ProcessInfo.processInfo.environment["API_URL"] ?? "https://navi-production-97dd.up.railway.app"
        #endif
    }
    private var authToken: String? {
        UserDefaults.standard.string(forKey: "authToken")
    }

    init() {
        setupNotificationObserver()
    }

    private func setupNotificationObserver() {
        tapLogger.info("🎧 TapManager: Setting up notification observer")
        NotificationCenter.default.publisher(for: .tapReceived)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                tapLogger.info("🔔 TapManager: Received tapReceived notification on main thread")
                if let tapMessage = notification.userInfo?["tapMessage"] as? TapMessage {
                    tapLogger.info("✅ TapManager: Got TapMessage from userInfo - intensity=\(tapMessage.intensity)")
                    Task { @MainActor in
                        self?.handleIncomingTap(tapMessage)
                    }
                } else {
                    tapLogger.error("❌ TapManager: Failed to get TapMessage from notification.userInfo")
                }
            }
            .store(in: &cancellables)
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
    
    @MainActor
    func handleIncomingTap(_ tapMessage: TapMessage) {
        tapLogger.info("💫 TapManager: handleIncomingTap called - intensity=\(tapMessage.intensity), pattern=\(tapMessage.pattern)")
        tapLogger.info("💫 TapManager: recentTaps count before: \(self.recentTaps.count)")
        self.recentTaps.insert(tapMessage, at: 0)
        tapLogger.info("💫 TapManager: recentTaps count after: \(self.recentTaps.count)")
        // Trigger haptic feedback
        Task {
            await self.triggerHapticFeedback(intensity: tapMessage.intensity, pattern: tapMessage.pattern)
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

// Local TapMessage definition (mirrors shared/Models/TapMessage.swift)
struct TapMessage: Codable, Identifiable {
    let fromUserId: String
    let toUserId: String
    let intensity: String
    let pattern: String
    let timestamp: String
    let id: String

    init(fromUserId: String, toUserId: String, intensity: String = "medium", pattern: String = "single", timestamp: String = ISO8601DateFormatter().string(from: Date()), id: String = UUID().uuidString) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.intensity = intensity
        self.pattern = pattern
        self.timestamp = timestamp
        self.id = id
    }
}