import SwiftUI

struct PhoneUnreachableView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone.slash")
                .font(.system(size: 50))
                .foregroundStyle(.gray)

            Text("iPhone Unavailable")
                .font(.headline)

            Text("Make sure Navi is open on your iPhone")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if connectivityManager.isPaired {
                Text("Watch is paired")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}

#Preview {
    PhoneUnreachableView()
        .environmentObject(WatchConnectivityManager.shared)
}
