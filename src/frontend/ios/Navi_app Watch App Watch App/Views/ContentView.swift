import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        Group {
            if !connectivityManager.isReachable {
                PhoneUnreachableView()
            } else if !connectivityManager.isAuthenticated {
                AuthenticationView()
            } else if !connectivityManager.isPairedWithPartner {
                PairingStatusView()
            } else {
                TapView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchConnectivityManager.shared)
}
