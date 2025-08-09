import XCTest
@testable import Navi_app

class PairingManagerTests: XCTestCase {
    var pairingManager: PairingManager!
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "pairedUserId")
        UserDefaults.standard.removeObject(forKey: "pairingRole")
        pairingManager = PairingManager()
    }
    
    override func tearDown() {
        pairingManager = nil
        super.tearDown()
    }
    
    func testInitialPairingState() {
        // Given a fresh PairingManager
        // Then pairing should be false
        XCTAssertFalse(pairingManager.isPaired)
        XCTAssertNil(pairingManager.pairedUserId)
        XCTAssertNil(pairingManager.pairingRole)
        XCTAssertNil(pairingManager.currentPairingCode)
    }
    
    func testGeneratePairingCode() {
        // When generating a pairing code
        let code = pairingManager.generatePairingCode()
        
        // Then it should be 6 digits
        XCTAssertEqual(code.count, 6)
        XCTAssertTrue(Int(code) != nil, "Code should be numeric")
        
        // And should be between 100000 and 999999
        if let numericCode = Int(code) {
            XCTAssertGreaterThanOrEqual(numericCode, 100000)
            XCTAssertLessThanOrEqual(numericCode, 999999)
        }
    }
    
    func testValidatePairingCode() {
        // Given various test codes
        let validCodes = ["123456", "000000", "999999", "555555"]
        let invalidCodes = ["12345", "1234567", "abcdef", "12 345", "", "1234a5"]
        
        // Then valid codes should pass
        for code in validCodes {
            XCTAssertTrue(isValidPairingCode(code), "\(code) should be valid")
        }
        
        // And invalid codes should fail
        for code in invalidCodes {
            XCTAssertFalse(isValidPairingCode(code), "\(code) should be invalid")
        }
    }
    
    func testLoadStoredPairing() {
        // Given stored pairing data
        let pairedUserId = "paired-user-789"
        let role = PairingRole.sender
        UserDefaults.standard.set(pairedUserId, forKey: "pairedUserId")
        UserDefaults.standard.set(role.rawValue, forKey: "pairingRole")
        
        // When creating a new PairingManager
        let newPairingManager = PairingManager()
        
        // Then it should load the stored pairing
        XCTAssertTrue(newPairingManager.isPaired)
        XCTAssertEqual(newPairingManager.pairedUserId, pairedUserId)
        XCTAssertEqual(newPairingManager.pairingRole, role)
    }
    
    func testClearPairingData() {
        // Given a paired state
        pairingManager.pairedUserId = "test-paired-user"
        pairingManager.pairingRole = .receiver
        pairingManager.isPaired = true
        pairingManager.currentPairingCode = "123456"
        
        // When clearing pairing data
        pairingManager.clearPairing()
        
        // Then all pairing data should be cleared
        XCTAssertFalse(pairingManager.isPaired)
        XCTAssertNil(pairingManager.pairedUserId)
        XCTAssertNil(pairingManager.pairingRole)
        XCTAssertNil(pairingManager.currentPairingCode)
        XCTAssertNil(UserDefaults.standard.string(forKey: "pairedUserId"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "pairingRole"))
    }
    
    // Helper function matching the one in PairingManager
    private func isValidPairingCode(_ code: String) -> Bool {
        let pattern = "^\\d{6}$"
        return code.range(of: pattern, options: .regularExpression) != nil
    }
}