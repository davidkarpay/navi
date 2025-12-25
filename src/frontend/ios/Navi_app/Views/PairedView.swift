import SwiftUI

struct PairedView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @EnvironmentObject var tapManager: TapManager
    @State private var isSending = false
    @State private var showSuccess = false
    @State private var showIncomingTap = false
    @State private var incomingIntensity = "medium"
    @State private var incomingPattern = "single"
    @State private var selectedIntensity = "medium"
    @State private var selectedPattern = "single"

    let intensities = ["light", "medium", "strong"]
    let patterns = ["single", "double", "triple", "heartbeat"]

    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                // Status
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                    Text("Connected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                Spacer()

                // Big Tap Button
                Button {
                    sendTap()
                } label: {
                    ZStack {
                        Circle()
                            .fill(showSuccess ? .green : .blue)
                            .frame(width: 180, height: 180)
                            .shadow(color: (showSuccess ? Color.green : Color.blue).opacity(0.4), radius: 20)

                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(2)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: showSuccess ? "checkmark" : "hand.tap.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                                Text(showSuccess ? "Sent!" : "TAP")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .disabled(isSending)
                .scaleEffect(isSending ? 0.95 : 1.0)
                .animation(.spring(response: 0.3), value: isSending)

                Spacer()

                // Options
                VStack(spacing: 16) {
                    // Intensity Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Intensity", selection: $selectedIntensity) {
                            ForEach(intensities, id: \.self) { intensity in
                                Text(intensity.capitalized).tag(intensity)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Pattern Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pattern")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Pattern", selection: $selectedPattern) {
                            ForEach(patterns, id: \.self) { pattern in
                                Text(pattern.capitalized).tag(pattern)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal)

                // Unpair button
                Button("Unpair", role: .destructive) {
                    Task {
                        await pairingManager.unpair()
                    }
                }
                .padding(.bottom, 30)
            }

            // Incoming tap overlay - size/opacity based on intensity
            if showIncomingTap {
                Circle()
                    .fill(Color.purple.opacity(opacityForIntensity(incomingIntensity)))
                    .scaleEffect(scaleForIntensity(incomingIntensity))
                    .allowsHitTesting(false)
            }
        }
        .navigationTitle("Navi")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: tapManager.recentTaps.count) { oldValue, newValue in
            if newValue > oldValue, let tap = tapManager.recentTaps.first {
                incomingIntensity = tap.intensity
                incomingPattern = tap.pattern
                playTapAnimation(pattern: tap.pattern)
            }
        }
    }

    private func sendTap() {
        isSending = true
        Task {
            let success = await tapManager.sendTap(intensity: selectedIntensity, pattern: selectedPattern)
            await MainActor.run {
                isSending = false
                if success {
                    showSuccess = true
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    // Reset after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSuccess = false
                    }
                }
            }
        }
    }

    private func playTapAnimation(pattern: String) {
        switch pattern {
        case "double":
            // Two flashes with gap
            flashOnce(duration: 0.2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                flashOnce(duration: 0.2)
            }
        case "triple":
            // Three flashes with gaps
            flashOnce(duration: 0.15)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                flashOnce(duration: 0.15)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                flashOnce(duration: 0.15)
            }
        case "heartbeat":
            // Lub-dub rhythm: quick-quick, pause, quick-quick
            flashOnce(duration: 0.1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                flashOnce(duration: 0.1)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                flashOnce(duration: 0.1)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                flashOnce(duration: 0.1)
            }
        default: // single
            flashOnce(duration: 0.4)
        }
    }

    private func flashOnce(duration: Double) {
        withAnimation(.easeOut(duration: duration / 2)) {
            showIncomingTap = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(.easeIn(duration: duration / 2)) {
                showIncomingTap = false
            }
        }
    }

    private func scaleForIntensity(_ intensity: String) -> CGFloat {
        switch intensity {
        case "light": return 1.5
        case "strong": return 3.5
        default: return 2.5
        }
    }

    private func opacityForIntensity(_ intensity: String) -> Double {
        switch intensity {
        case "light": return 0.2
        case "strong": return 0.5
        default: return 0.3
        }
    }
}

#Preview {
    NavigationStack {
        PairedView()
            .environmentObject(PairingManager())
            .environmentObject(TapManager())
    }
}
