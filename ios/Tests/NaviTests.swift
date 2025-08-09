import XCTest
@testable import NaviShared

final class NaviTests: XCTestCase {
    
    func testTapMessageCreation() {
        let senderId = "user1"
        let receiverId = "user2"
        let tapMessage = TapMessage(senderId: senderId, receiverId: receiverId)
        
        XCTAssertEqual(tapMessage.senderId, senderId)
        XCTAssertEqual(tapMessage.receiverId, receiverId)
        XCTAssertNotNil(tapMessage.id)
        XCTAssertNotNil(tapMessage.timestamp)
    }
    
    func testConstants() {
        XCTAssertEqual(Constants.appGroup, "group.com.yourcompany.navi")
        XCTAssertEqual(Constants.Notification.categoryIdentifier, "TAP_RECEIVED")
        XCTAssertEqual(Constants.UserDefaults.userId, "userId")
    }
    
    func testPairingCodeValidation() {
        func isValidPairingCode(_ code: String) -> Bool {
            let pattern = "^\\d{6}$"
            return code.range(of: pattern, options: .regularExpression) != nil
        }
        
        XCTAssertTrue(isValidPairingCode("123456"))
        XCTAssertFalse(isValidPairingCode("12345"))
        XCTAssertFalse(isValidPairingCode("1234567"))
        XCTAssertFalse(isValidPairingCode("abcdef"))
    }
}