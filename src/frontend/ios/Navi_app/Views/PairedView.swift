import SwiftUI

struct PairedView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @EnvironmentObject var tapManager: TapManager
    @State private var isSending = false
    @State private var tapState: TapState = .idle
    @State private var showIncomingTap = false
    @State private var incomingIntensity = "medium"
    @State private var selectedIntensity = "medium"
    @State private var selectedPattern = "single"

    /// Tap button states following design spec
    enum TapState {
        case idle           // Blue Glow, minimal halo
        case pressed        // Blue intensifies, inner ripple
        case sent           // Outward ripple, Red response briefly
        case disconnected   // Blue dims, no red (silence, not error)
    }

    let intensities = ["light", "medium", "strong"]
    let patterns = ["single", "double", "triple", "heartbeat"]

    var body: some View {
        ZStack {
            // Incoming tap overlay - uses overlap motif for confirmation
            if showIncomingTap {
                NaviMotifIcon(motif: .overlapBlueRed)
                    .opacity(opacityForIntensity(incomingIntensity))
                    .scaleEffect(scaleForIntensity(incomingIntensity))
                    .allowsHitTesting(false)
            }

            VStack(spacing: 30) {
                // Status indicator using connection state asset
                HStack(spacing: 8) {
                    NaviConnectionIcon(state: .connectedOverlap, size: 24)
                    Text("Connected")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(.top)

                Spacer()

                // Tap Button - uses glow assets for states
                Button {
                    sendTap()
                } label: {
                    ZStack {
                        // Ripple effect on sent - use ripple asset
                        if tapState == .sent {
                            NaviMotifIcon(motif: rippleMotifForPattern, size: 280)
                                .opacity(0.6)
                                .scaleEffect(1.3)
                                .animation(.easeOut(duration: 0.5), value: tapState)
                        }

                        // Main tap button - uses tap state assets with alive glow
                        NaviTapIcon(state: tapState == .pressed ? .pressedBlue : .idleBlue, size: 200)
                            .scaleEffect(tapState == .pressed ? 0.95 : 1.0)
                            .animation(.spring(response: 0.3), value: tapState)

                        // Content overlay
                        if isSending {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryText))
                                .scaleEffect(2)
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "hand.tap.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(AppTheme.primaryText)

                                Text("TAP")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.primaryText)
                            }
                        }
                    }
                }
                .disabled(isSending)

                Spacer()

                // Intensity & Pattern - radial feel, not linear
                VStack(spacing: 16) {
                    // Intensity = amplitude
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intensity")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Picker("Intensity", selection: $selectedIntensity) {
                            ForEach(intensities, id: \.self) { intensity in
                                Text(intensity.capitalized).tag(intensity)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(AppTheme.blueGlow)
                    }

                    // Pattern = timing
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pattern")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Picker("Pattern", selection: $selectedPattern) {
                            ForEach(patterns, id: \.self) { pattern in
                                Text(pattern.capitalized).tag(pattern)
                            }
                        }
                        .pickerStyle(.segmented)
                        .tint(AppTheme.blueGlow)
                    }
                }
                .padding(.horizontal)

                // Unpair - subtle, not destructive red
                Button {
                    Task {
                        await pairingManager.unpair()
                    }
                } label: {
                    Text("Unpair")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Navi")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: tapManager.recentTaps.count) { oldValue, newValue in
            if newValue > oldValue, let tap = tapManager.recentTaps.first {
                incomingIntensity = tap.intensity
                playIncomingTapAnimation(pattern: tap.pattern)
            }
        }
    }

    // MARK: - Computed Properties

    /// Ripple motif based on selected pattern
    private var rippleMotifForPattern: NaviCoreMotif {
        switch selectedPattern {
        case "double": return .rippleDouble
        case "triple": return .rippleTriple
        default: return .rippleSingle
        }
    }

    // MARK: - Actions

    private func sendTap() {
        isSending = true
        tapState = .pressed

        Task {
            let success = await tapManager.sendTap(intensity: selectedIntensity, pattern: selectedPattern)
            await MainActor.run {
                isSending = false
                if success {
                    tapState = .sent
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    // Reset to idle after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            tapState = .idle
                        }
                    }
                } else {
                    tapState = .idle
                }
            }
        }
    }

    // MARK: - Incoming Tap Animation

    private func playIncomingTapAnimation(pattern: String) {
        switch pattern {
        case "double":
            flashOnce(duration: 0.2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                flashOnce(duration: 0.2)
            }
        case "triple":
            flashOnce(duration: 0.15)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                flashOnce(duration: 0.15)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                flashOnce(duration: 0.15)
            }
        case "heartbeat":
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
        ZStack {
            AppTheme.midnight.ignoresSafeArea()
            PairedView()
                .environmentObject(PairingManager())
                .environmentObject(TapManager())
        }
    }
}
