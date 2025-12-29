import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var pairingManager: PairingManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Midnight background - absence, silence
                AppTheme.midnight
                    .ignoresSafeArea()

                if !authManager.isAuthenticated {
                    WelcomeView()
                } else if !pairingManager.isPaired {
                    PairingView()
                } else {
                    PairedView()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(PairingManager())
        .environmentObject(TapManager())
}
