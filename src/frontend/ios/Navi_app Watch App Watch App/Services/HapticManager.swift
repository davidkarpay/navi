import Foundation
import WatchKit

class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func playTapReceivedHaptic() {
        // Play a notification haptic when a tap is received
        WKInterfaceDevice.current().play(.notification)
    }
    
    func playTapSentHaptic() {
        // Play a click haptic when sending a tap
        WKInterfaceDevice.current().play(.click)
    }
    
    func playSuccessHaptic() {
        // Play success haptic for successful operations
        WKInterfaceDevice.current().play(.success)
    }
    
    func playErrorHaptic() {
        // Play failure haptic for errors
        WKInterfaceDevice.current().play(.failure)
    }
}