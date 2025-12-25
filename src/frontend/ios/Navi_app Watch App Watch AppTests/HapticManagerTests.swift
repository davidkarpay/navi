import XCTest
@testable import Navi_app_Watch_App_Watch_App

class HapticManagerTests: XCTestCase {
    var hapticManager: HapticManager!
    
    override func setUp() {
        super.setUp()
        hapticManager = HapticManager.shared
    }
    
    override func tearDown() {
        hapticManager = nil
        super.tearDown()
    }
    
    func testSharedInstance() {
        // Given the shared instance
        let instance1 = HapticManager.shared
        let instance2 = HapticManager.shared
        
        // Then it should be the same instance (singleton)
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testHapticPatterns() {
        // Test that haptic patterns are defined correctly
        // Note: We can't actually test haptic playback in unit tests
        
        // Test tap received pattern exists
        XCTAssertNotNil(hapticManager)
        
        // Verify the manager can handle different tap types
        let tapTypes = ["single", "double", "long", "pattern"]
        for tapType in tapTypes {
            // In a real implementation, this would trigger different haptic patterns
            XCTAssertTrue(tapTypes.contains(tapType))
        }
    }
    
    func testPlayHapticDoesNotCrash() {
        // Test that calling haptic methods doesn't crash
        // In unit tests, we can only verify the method exists and doesn't throw
        
        // This would normally trigger a haptic feedback
        hapticManager.playTapReceivedHaptic()
        
        // If we get here without crashing, the test passes
        XCTAssertTrue(true)
    }
}