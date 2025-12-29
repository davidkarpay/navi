import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.circle")
                .font(.system(size: 50))
                .foregroundStyle(WatchTheme.blueGlow)

            Text("Open Navi on iPhone")
                .font(.headline)
                .foregroundStyle(WatchTheme.primaryText)
                .multilineTextAlignment(.center)

            Text("Complete setup to continue")
                .font(.caption)
                .foregroundStyle(WatchTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                connectivityManager.requestStateFromPhone()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .tint(WatchTheme.blueGlow)
        }
        .padding()
        .background(WatchTheme.midnight)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(WatchConnectivityManager.shared)
}
