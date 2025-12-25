import SwiftUI

struct CreateCodeView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @Environment(\.dismiss) var dismiss
    @State private var pairingCode: String?
    @State private var isLoading = true
    @State private var isWaiting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()

                if isLoading {
                    ProgressView("Generating code...")
                } else if let code = pairingCode {
                    VStack(spacing: 20) {
                        Text("Your Pairing Code")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text(code)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .tracking(8)

                        Text("Share this code with your partner")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if isWaiting {
                            HStack(spacing: 8) {
                                ProgressView()
                                Text("Waiting for partner...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 20)
                        }
                    }
                }

                Spacer()
            }
            .navigationTitle("Create Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            if let code = await pairingManager.createPairingCode() {
                pairingCode = code
                isLoading = false
                isWaiting = true
                // Poll for pairing completion
                await pollForPairing()
            }
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
}
