import Foundation
import SwiftUI

enum PairingRole: String {
    case sender
    case receiver
}

class PairingManager: ObservableObject {
    @Published var isPaired = false
    @Published var pairedUserId: String?
    @Published var pairingRole: PairingRole?
    @Published var currentPairingCode: String?
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadStoredPairing()
    }
    
    private func loadStoredPairing() {
        if let pairedUserId = userDefaults.string(forKey: "pairedUserId"),
           let roleString = userDefaults.string(forKey: "pairingRole"),
           let role = PairingRole(rawValue: roleString) {
            self.pairedUserId = pairedUserId
            self.pairingRole = role
            self.isPaired = true
        }
    }
    
    func generatePairingCode() -> String {
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        currentPairingCode = code
        return code
    }
    
    func clearPairing() {
        isPaired = false
        pairedUserId = nil
        pairingRole = nil
        currentPairingCode = nil
        userDefaults.removeObject(forKey: "pairedUserId")
        userDefaults.removeObject(forKey: "pairingRole")
    }
}