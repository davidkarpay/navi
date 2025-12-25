import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var pairingManager: PairingManager

    var body: some View {
        NavigationStack {
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

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(PairingManager())
        .environmentObject(TapManager())
}
