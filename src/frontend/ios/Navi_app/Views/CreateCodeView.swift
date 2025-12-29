import SwiftUI

struct CreateCodeView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var pairingCode: String?
    @State private var isLoading = true
    @State private var isWaiting = false
    @State private var errorMessage: String?
    @State private var needsReauth = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.midnight.ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    if isLoading {
                        ProgressView("Generating code...")
                            .foregroundColor(AppTheme.primaryText)
                            .tint(AppTheme.blueGlow)
                    } else if let error = errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)

                            Text("Unable to Generate Code")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)

                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            if needsReauth {
                                Button {
                                    isLoading = true
                                    errorMessage = nil
                                    needsReauth = false
                                    Task {
                                        await authManager.registerAnonymousUser()
                                        await generateCode()
                                    }
                                } label: {
                                    Label("Reconnect", systemImage: "arrow.triangle.2.circlepath")
                                        .fontWeight(.semibold)
                                        .padding()
                                        .background(AppTheme.blueGlow)
                                        .foregroundColor(AppTheme.midnight)
                                        .cornerRadius(12)
                                }
                            } else {
                                Button {
                                    isLoading = true
                                    errorMessage = nil
                                    Task {
                                        await generateCode()
                                    }
                                } label: {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                        .fontWeight(.semibold)
                                        .padding()
                                        .background(AppTheme.blueGlow)
                                        .foregroundColor(AppTheme.midnight)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    } else if let code = pairingCode {
                        VStack(spacing: 20) {
                            Text("Your Pairing Code")
                                .font(.headline)
                                .foregroundStyle(AppTheme.secondaryText)

                            Text(code)
                                .font(.system(size: 48, weight: .bold, design: .monospaced))
                                .tracking(8)
                                .foregroundColor(AppTheme.blueGlow)

                            Text("Share this code with your partner")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)

                            if isWaiting {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(AppTheme.blueGlow)
                                    Text("Waiting for partner...")
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                .padding(.top, 20)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("Create Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.blueGlow)
                }
            }
        }
        .task {
            await generateCode()
        }
    }

    private func generateCode() async {
        if let code = await pairingManager.createPairingCode() {
            pairingCode = code
            isLoading = false
            isWaiting = true
            // Poll for pairing completion
            await pollForPairing()
        } else {
            isLoading = false
            needsReauth = true
            errorMessage = "Your session has expired. Tap Reconnect to refresh your connection."
        }
    }

    private func pollForPairing() async {
        for _ in 0..<60 { // Poll for up to 5 minutes
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            pairingManager.checkPairingStatus()
            if pairingManager.isPaired {
                dismiss()
                return
            }
        }
    }
}

#Preview {
    CreateCodeView()
        .environmentObject(PairingManager())
        .environmentObject(AuthManager())
}
