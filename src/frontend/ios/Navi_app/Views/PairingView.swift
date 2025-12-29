import SwiftUI

struct PairingView: View {
    @State private var showCreateCode = false
    @State private var showJoinCode = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 16) {
                // Pairing approach state - two circles approaching with alive glow
                NaviConnectionIcon(state: .pairingApproach, size: 100)

                Text("Pair with Partner")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryText)

                Text("Connect with your partner to start sending taps")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                // Primary action - Blue Glow (You / Initiation)
                Button {
                    showCreateCode = true
                } label: {
                    Label("Create Code", systemImage: "plus.circle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.blueGlow)
                        .foregroundColor(AppTheme.midnight)
                        .cornerRadius(12)
                }

                // Secondary action - subtle
                Button {
                    showJoinCode = true
                } label: {
                    Label("Join with Code", systemImage: "arrow.right.circle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.blueGlow.opacity(0.15))
                        .foregroundColor(AppTheme.blueGlow)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showCreateCode) {
            CreateCodeView()
        }
        .sheet(isPresented: $showJoinCode) {
            JoinCodeView()
        }
    }
}

#Preview {
    ZStack {
        AppTheme.midnight.ignoresSafeArea()
        PairingView()
            .environmentObject(PairingManager())
    }
}
