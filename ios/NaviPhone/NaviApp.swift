import SwiftUI

@main
struct NaviApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var authManager = AuthManager()
    @StateObject private var pairingManager = PairingManager()
    @StateObject private var notificationManager = NotificationManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(pairingManager)
                .environmentObject(notificationManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        notificationManager.requestAuthorization()
        
        if authManager.isAuthenticated {
            pairingManager.checkPairingStatus()
        }
    }
}