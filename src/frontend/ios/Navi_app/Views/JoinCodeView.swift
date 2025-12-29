import SwiftUI

struct JoinCodeView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @Environment(\.dismiss) var dismiss
    @State private var code = ""
    @State private var isJoining = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.midnight.ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    VStack(spacing: 20) {
                        Text("Enter Partner's Code")
                            .font(.headline)
                            .foregroundStyle(AppTheme.secondaryText)

                        TextField("000000", text: $code)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .frame(maxWidth: 200)
                            .foregroundColor(AppTheme.blueGlow)
                            .onChange(of: code) { _, newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    code = String(newValue.prefix(6))
                                }
                                // Only allow digits
                                code = newValue.filter { $0.isNumber }
                            }

                        if let error = errorMessage {
                            Text(error)
                                .foregroundStyle(AppTheme.redGlow)
                                .font(.subheadline)
                        }
                    }

                    Spacer()

                    Button {
                        joinWithCode()
                    } label: {
                        if isJoining {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.midnight))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.blueGlow)
                                .cornerRadius(12)
                        } else {
                            Text("Join")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(code.count == 6 ? AppTheme.blueGlow : AppTheme.blueGlowDim)
                                .foregroundColor(AppTheme.midnight)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(code.count != 6 || isJoining)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Join with Code")
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
    }

    private func joinWithCode() {
        isJoining = true
        errorMessage = nil

        Task {
            let success = await pairingManager.joinWithCode(code)
            await MainActor.run {
                isJoining = false
                if success {
                    dismiss()
                } else {
                    errorMessage = "Invalid or expired code"
                }
            }
        }
    }
}

#Preview {
    JoinCodeView()
        .environmentObject(PairingManager())
}
