import SwiftUI

@main
struct NaviApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authManager = AuthManager()
    @StateObject private var pairingManager = PairingManager()
    @StateObject private var tapManager = TapManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(pairingManager)
                .environmentObject(tapManager)
                .onAppear {
                    // Configure Watch connectivity
                    WatchConnectivityService.shared.configure(
                        auth: authManager,
                        pairing: pairingManager,
                        tap: tapManager
                    )
                }
        }
    }
}
