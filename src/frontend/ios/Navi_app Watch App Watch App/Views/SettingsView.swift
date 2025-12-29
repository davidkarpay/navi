import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Connection") {
                    HStack {
                        Text("iPhone")
                        Spacer()
                        Circle()
                            .fill(connectivityManager.isReachable ? WatchTheme.success : WatchTheme.blueGlowDim)
                            .frame(width: 10, height: 10)
                        Text(connectivityManager.isReachable ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundStyle(WatchTheme.secondaryText)
                    }

                    HStack {
                        Text("Watch Paired")
                        Spacer()
                        Circle()
                            .fill(connectivityManager.isPaired ? WatchTheme.blueGlow : WatchTheme.blueGlowDim)
                            .frame(width: 10, height: 10)
                        Text(connectivityManager.isPaired ? "Yes" : "No")
                            .font(.caption)
                            .foregroundStyle(WatchTheme.secondaryText)
                    }
                }

                Section("Partner") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(connectivityManager.isPairedWithPartner ? "Paired" : "Not Paired")
                            .font(.caption)
                            .foregroundStyle(WatchTheme.secondaryText)
                    }
                }

                Section {
                    Button {
                        connectivityManager.requestStateFromPhone()
                    } label: {
                        Label("Refresh Status", systemImage: "arrow.clockwise")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .font(.caption)
                            .foregroundStyle(WatchTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(WatchConnectivityManager.shared)
}
