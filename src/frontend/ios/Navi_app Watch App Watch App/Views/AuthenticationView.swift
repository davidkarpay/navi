import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.circle")
                .font(.system(size: 50))
                .foregroundStyle(.blue)

            Text("Open Navi on iPhone")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Complete setup to continue")
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
    AuthenticationView()
        .environmentObject(WatchConnectivityManager.shared)
}
