import SwiftUI

struct TapView: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager

    @State private var selectedIntensity = "medium"
    @State private var selectedPattern = "single"
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showIncomingTap = false
    @State private var showSettings = false

    let intensities = ["light", "medium", "strong"]
    let patterns = ["single", "double", "triple", "heartbeat"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Main tap button
                    Button {
                        sendTap()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(buttonColor)
                                .frame(width: 100, height: 100)

                            if isSending {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                VStack(spacing: 4) {
                                    Image(systemName: buttonIcon)
                                        .font(.system(size: 36))
                                        .foregroundStyle(.white)
                                    Text(buttonText)
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)

                    // Intensity picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Intensity")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker("Intensity", selection: $selectedIntensity) {
                            ForEach(intensities, id: \.self) { intensity in
                                Text(intensity.capitalized).tag(intensity)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 50)
                    }

                    // Pattern picker
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pattern")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Picker("Pattern", selection: $selectedPattern) {
                            ForEach(patterns, id: \.self) { pattern in
                                Text(pattern.capitalized).tag(pattern)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 50)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Navi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onChange(of: connectivityManager.lastReceivedTap) { oldValue, newValue in
                if newValue != nil && newValue != oldValue {
                    // Visual feedback for incoming tap
                    showIncomingTap = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showIncomingTap = false
                    }
                }
            }
            .overlay {
                if showIncomingTap {
                    Circle()
                        .fill(Color.purple.opacity(0.4))
                        .scaleEffect(2.5)
                        .allowsHitTesting(false)
                        .animation(.easeOut(duration: 0.3), value: showIncomingTap)
                }
            }
        }
    }

    private var buttonColor: Color {
        if showSuccess {
            return .green
        } else if showIncomingTap {
            return .purple
        } else {
            return .blue
        }
    }

    private var buttonIcon: String {
        showSuccess ? "checkmark" : "hand.tap.fill"
    }

    private var buttonText: String {
        showSuccess ? "Sent!" : "TAP"
    }

    private func sendTap() {
        isSending = true
        HapticManager.shared.playTapSentHaptic()

        connectivityManager.sendTapToPhone(
            intensity: selectedIntensity,
            pattern: selectedPattern
        ) { success in
            isSending = false
            if success {
                showSuccess = true
                HapticManager.shared.playSuccessHaptic()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showSuccess = false
                }
            } else {
                HapticManager.shared.playErrorHaptic()
            }
        }
    }
}

#Preview {
    TapView()
        .environmentObject(WatchConnectivityManager.shared)
}
