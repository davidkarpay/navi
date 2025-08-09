import SwiftUI

struct PairingView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @State private var showCreateCode = false
    @State private var showJoinCode = false
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 15) {
                Image(systemName: "person.2.circle")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Pair Your Watches")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Connect with your partner to start sending taps")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            Spacer()
            
            VStack(spacing: 20) {
                Button(action: {
                    showCreateCode = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "qrcode")
                            .font(.title)
                        Text("Create Pairing Code")
                            .font(.headline)
                        Text("Generate a code for your partner")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    showJoinCode = true
                }) {
                    VStack(spacing: 10) {
                        Image(systemName: "keyboard")
                            .font(.title)
                        Text("Enter Partner's Code")
                            .font(.headline)
                        Text("Join using your partner's code")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .navigationTitle("Pairing")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateCode) {
            CreateCodeView()
        }
        .sheet(isPresented: $showJoinCode) {
            JoinCodeView()
        }
    }
}