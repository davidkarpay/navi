import SwiftUI

struct PairingStatusView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "link.circle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)

            Text("Not Paired")
                .font(.headline)

            Text("Pair with your partner on iPhone to start sending taps")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                connectivityManager.requestStateFromPhone()
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    PairingStatusView()
        .environmentObject(WatchConnectivityManager.shared)
}
