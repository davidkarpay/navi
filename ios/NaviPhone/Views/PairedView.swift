import SwiftUI

struct PairedView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @StateObject private var tapManager = TapManager()
    @State private var showUnpairAlert = false
    @State private var lastTapTime: String = ""
    
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
            
            // Tap Buttons
            VStack(spacing: 15) {
                Text("Send a Tap")
                    .font(.headline)
                    .padding(.bottom, 5)
                
                HStack(spacing: 15) {
                    TapButton(title: "Light", icon: "hand.tap", intensity: "light", pattern: "single", tapManager: tapManager)
                    TapButton(title: "Medium", icon: "hand.tap.fill", intensity: "medium", pattern: "single", tapManager: tapManager)
                    TapButton(title: "Strong", icon: "burst.fill", intensity: "strong", pattern: "single", tapManager: tapManager)
                }
                
                HStack(spacing: 15) {
                    TapButton(title: "Double", icon: "hand.tap", intensity: "medium", pattern: "double", tapManager: tapManager)
                    TapButton(title: "Triple", icon: "hand.tap", intensity: "medium", pattern: "triple", tapManager: tapManager)
                    TapButton(title: "❤️", icon: "heart.fill", intensity: "medium", pattern: "heartbeat", tapManager: tapManager)
                }
                
                if !lastTapTime.isEmpty {
                    Text("Last sent: \(lastTapTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 5)
                }
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
        .onReceive(NotificationCenter.default.publisher(for: .tapReceived)) { notification in
            if let tapMessage = notification.object as? TapMessage {
                tapManager.handleIncomingTap(tapMessage)
            }
        }
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

struct TapButton: View {
    let title: String
    let icon: String
    let intensity: String
    let pattern: String
    let tapManager: TapManager
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            Task {
                let success = await tapManager.sendTap(intensity: intensity, pattern: pattern)
                if success {
                    // Update last tap time in parent view would require binding
                    print("Tap sent: \(intensity) \(pattern)")
                }
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 70, height: 60)
            .background(isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}