import SwiftUI

struct PhoneUnreachableView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 50))
                .foregroundStyle(WatchTheme.blueGlowDim)

            Text("iPhone Unavailable")
                .font(.headline)
                .foregroundStyle(WatchTheme.primaryText)

            Text("Make sure Navi is open on your iPhone")
                .font(.caption)
                .foregroundStyle(WatchTheme.secondaryText)
                .multilineTextAlignment(.center)

            if connectivityManager.isPaired {
                Text("Watch is paired")
                    .font(.caption2)
                    .foregroundStyle(WatchTheme.blueGlowSubtle)
            }
        }
        .padding()
        .background(WatchTheme.midnight)
    }
}

#Preview {
    PhoneUnreachableView()
        .environmentObject(WatchConnectivityManager.shared)
}
