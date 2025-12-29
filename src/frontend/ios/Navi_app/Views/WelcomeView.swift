import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                // Blue glow ring motif with alive animation
                AliveGlowImage(assetName: "motif_ring_blue", config: .calm)
                    .frame(width: 120, height: 120)

                Text("Navi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryText)

                Text("Send taps to your partner")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Button {
                isLoading = true
                Task {
                    await authManager.registerAnonymousUser()
                    isLoading = false
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryText))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.blueGlow)
                        .cornerRadius(12)
                } else {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.blueGlow)
                        .foregroundColor(AppTheme.midnight)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoading)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.midnight.ignoresSafeArea()
        WelcomeView()
            .environmentObject(AuthManager())
    }
}
