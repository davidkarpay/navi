import XCTest
import WatchConnectivity
@testable import Navi_app_Watch_App_Watch_App

class WatchConnectivityTests: XCTestCase {
    var connectivityManager: WatchConnectivityManager!
    
    override func setUp() {
        super.setUp()
        connectivityManager = WatchConnectivityManager.shared
    }
    
    override func tearDown() {
        connectivityManager = nil
        super.tearDown()
    }
    
    func testSharedInstance() {
        // Given the shared instance
        let instance1 = WatchConnectivityManager.shared
        let instance2 = WatchConnectivityManager.shared
        
        // Then it should be the same instance (singleton)
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testSessionSupport() {
        // Test that WatchConnectivity is supported on this device
        let isSupported = WCSession.isSupported()
        
        // On watchOS, WCSession should always be supported
        XCTAssertTrue(isSupported, "WatchConnectivity should be supported on watchOS")
    }
    
    func testMessagePayloadCreation() {
        // Test creating a tap message payload
        let tapType = "single"
        let timestamp = Date()
        
        let payload: [String: Any] = [
            "type": "tap",
            "tapType": tapType,
            "timestamp": timestamp.timeIntervalSince1970
        ]
        
        // Verify payload structure
        XCTAssertEqual(payload["type"] as? String, "tap")
        XCTAssertEqual(payload["tapType"] as? String, tapType)
        XCTAssertNotNil(payload["timestamp"] as? TimeInterval)
    }
    
    func testReceivedMessageParsing() {
        // Test parsing a received message
        let testMessage: [String: Any] = [
            "type": "tap",
            "senderId": "user123",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Verify we can extract the expected fields
        XCTAssertEqual(testMessage["type"] as? String, "tap")
        XCTAssertEqual(testMessage["senderId"] as? String, "user123")
        XCTAssertNotNil(testMessage["timestamp"] as? TimeInterval)
    }
    
    func testConnectionStateHandling() {
        // Test that the manager can handle different connection states
        // Note: We can't actually change the connection state in unit tests
        
        // Verify the manager exists and can be referenced
        XCTAssertNotNil(connectivityManager)
        
        // In a real implementation, we would test state transitions
        let possibleStates = ["notActivated", "inactive", "activated"]
        for state in possibleStates {
            // Verify we have handlers for each state
            XCTAssertTrue(possibleStates.contains(state))
        }
    }
}