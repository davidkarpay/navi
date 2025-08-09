import SwiftUI

struct CreateCodeView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @Environment(\.dismiss) var dismiss
    @State private var pairingCode: String?
    @State private var isLoading = true
    @State private var timeRemaining = 300 // 5 minutes
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                if isLoading {
                    ProgressView("Generating code...")
                        .padding(.top, 100)
                } else if let code = pairingCode {
                    VStack(spacing: 20) {
                        Text("Share this code with your partner")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text(code)
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Expires in \(timeString)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                }
                
                Spacer()
                
                if !isLoading {
                    Text("Waiting for partner to join...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Pairing Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await createPairingCode()
            }
        }
        .onReceive(timer) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                dismiss()
            }
        }
        .onChange(of: pairingManager.isPaired) { isPaired in
            if isPaired {
                dismiss()
            }
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func createPairingCode() async {
        isLoading = true
        if let code = await pairingManager.createPairingCode() {
            pairingCode = code
        }
        isLoading = false
    }
}