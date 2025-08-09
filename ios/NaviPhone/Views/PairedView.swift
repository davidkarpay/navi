import SwiftUI

struct PairedView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @State private var showUnpairAlert = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Paired Successfully!")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("You can now send taps from your Apple Watch")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 60)
            
            Spacer()
            
            VStack(spacing: 20) {
                HStack {
                    Image(systemName: "applewatch")
                        .font(.title2)
                    Text("Open the Navi app on your Apple Watch")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.title2)
                    Text("Tap the button to send a buzz")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button(action: {
                showUnpairAlert = true
            }) {
                Text("Unpair")
                    .foregroundColor(.red)
            }
            .padding(.bottom, 30)
        }
        .navigationTitle("Connected")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Unpair Device", isPresented: $showUnpairAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Unpair", role: .destructive) {
                Task {
                    await pairingManager.unpair()
                }
            }
        } message: {
            Text("Are you sure you want to unpair? You'll need a new code to reconnect.")
        }
    }
}