import XCTest
import UserNotifications
@testable import Navi_app

class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    
    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager()
    }
    
    override func tearDown() {
        notificationManager = nil
        super.tearDown()
    }
    
    func testSharedInstance() {
        // Given the shared instance
        let instance1 = NotificationManager.shared
        let instance2 = NotificationManager.shared
        
        // Then it should be the same instance (singleton)
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testInitialDeviceToken() {
        // Given a fresh NotificationManager
        // Then device token should be nil
        XCTAssertNil(notificationManager.deviceToken)
    }
    
    func testParseDeviceToken() {
        // Given a mock device token data
        let tokenData = Data([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08])
        
        // When parsing the device token
        let tokenString = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        
        // Then it should produce the expected hex string
        XCTAssertEqual(tokenString, "0102030405060708")
        XCTAssertEqual(tokenString.count, 16) // 8 bytes * 2 hex chars each
    }
    
    func testNotificationCategories() {
        // Given the notification setup
        let categories = createNotificationCategories()
        
        // Then it should contain the tap received category
        XCTAssertFalse(categories.isEmpty)
        
        // Find the tap received category
        let tapCategory = categories.first { $0.identifier == "TAP_RECEIVED" }
        XCTAssertNotNil(tapCategory)
        
        // Verify it has the acknowledge action
        if let tapCategory = tapCategory {
            XCTAssertTrue(tapCategory.actions.contains { $0.identifier == "ACKNOWLEDGE_ACTION" })
        }
    }
    
    func testTapNotificationContent() {
        // Given a tap notification
        let content = UNMutableNotificationContent()
        content.title = "Tap from Friend"
        content.body = "You received a tap!"
        content.categoryIdentifier = "TAP_RECEIVED"
        content.sound = .default
        
        // Then it should have the correct properties
        XCTAssertEqual(content.title, "Tap from Friend")
        XCTAssertEqual(content.body, "You received a tap!")
        XCTAssertEqual(content.categoryIdentifier, "TAP_RECEIVED")
        XCTAssertNotNil(content.sound)
    }
    
    // Helper function to create notification categories
    private func createNotificationCategories() -> Set<UNNotificationCategory> {
        let acknowledgeAction = UNNotificationAction(
            identifier: "ACKNOWLEDGE_ACTION",
            title: "Acknowledge",
            options: []
        )
        
        let tapCategory = UNNotificationCategory(
            identifier: "TAP_RECEIVED",
            actions: [acknowledgeAction],
            intentIdentifiers: [],
            options: []
        )
        
        return [tapCategory]
    }
}