import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var pairingManager: PairingManager
    
    var body: some View {
        NavigationView {
            if !authManager.isAuthenticated {
                WelcomeView()
            } else if !pairingManager.isPaired {
                PairingView()
            } else {
                PairedView()
            }
        }
    }
}