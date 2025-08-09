import Foundation

public struct TapMessage: Codable {
    public let fromUserId: String
    public let toUserId: String
    public let intensity: String // "light", "medium", "strong"
    public let pattern: String   // "single", "double", "triple", "heartbeat"
    public let timestamp: String
    public let id: String
    
    public init(fromUserId: String, toUserId: String, intensity: String = "medium", pattern: String = "single", timestamp: String = ISO8601DateFormatter().string(from: Date()), id: String = UUID().uuidString) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.intensity = intensity
        self.pattern = pattern
        self.timestamp = timestamp
        self.id = id
    }
}