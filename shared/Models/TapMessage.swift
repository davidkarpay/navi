import Foundation

public struct TapMessage: Codable {
    public let senderId: String
    public let receiverId: String
    public let timestamp: Date
    public let id: UUID
    
    public init(senderId: String, receiverId: String, timestamp: Date = Date(), id: UUID = UUID()) {
        self.senderId = senderId
        self.receiverId = receiverId
        self.timestamp = timestamp
        self.id = id
    }
}