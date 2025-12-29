import SwiftUI

struct PairingStatusView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.circle")
                .font(.system(size: 50))
                .foregroundStyle(WatchTheme.blueGlow)

            Text("Not Paired")
                .font(.headline)
                .foregroundStyle(WatchTheme.primaryText)

            Text("Pair with your partner on iPhone to start sending taps")
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
    PairingStatusView()
        .environmentObject(WatchConnectivityManager.shared)
}
