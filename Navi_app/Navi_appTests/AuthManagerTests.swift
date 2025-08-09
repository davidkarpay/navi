import XCTest
@testable import Navi_app

class AuthManagerTests: XCTestCase {
    var authManager: AuthManager!
    
    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "authToken")
        authManager = AuthManager()
    }
    
    override func tearDown() {
        authManager = nil
        super.tearDown()
    }
    
    func testInitialAuthenticationState() {
        // Given a fresh AuthManager
        // Then authentication should be false
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.userId)
        XCTAssertNil(authManager.authToken)
    }
    
    func testLoadStoredAuth() {
        // Given stored credentials
        let testUserId = "test-user-123"
        let testToken = "test-token-456"
        UserDefaults.standard.set(testUserId, forKey: "userId")
        UserDefaults.standard.set(testToken, forKey: "authToken")
        
        // When creating a new AuthManager
        let newAuthManager = AuthManager()
        
        // Then it should load the stored credentials
        XCTAssertTrue(newAuthManager.isAuthenticated)
        XCTAssertEqual(newAuthManager.userId, testUserId)
        XCTAssertEqual(newAuthManager.authToken, testToken)
    }
    
    func testClearAuthData() {
        // Given an authenticated user
        authManager.userId = "test-user"
        authManager.authToken = "test-token"
        authManager.isAuthenticated = true
        
        // When clearing auth data
        authManager.clearAuthData()
        
        // Then all auth data should be cleared
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.userId)
        XCTAssertNil(authManager.authToken)
        XCTAssertNil(UserDefaults.standard.string(forKey: "userId"))
        XCTAssertNil(UserDefaults.standard.string(forKey: "authToken"))
    }
    
    func testBaseURLFromEnvironment() {
        // The base URL should use the default production URL
        let expectedURL = "https://navi-production-97dd.up.railway.app"
        XCTAssertEqual(authManager.baseURL, expectedURL)
    }
}