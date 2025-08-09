import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Navi")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Stay connected with a tap")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                Task {
                    await setupUser()
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Get Started")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(isLoading)
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .navigationBarHidden(true)
    }
    
    private func setupUser() async {
        isLoading = true
        await authManager.registerAnonymousUser()
        isLoading = false
    }
}