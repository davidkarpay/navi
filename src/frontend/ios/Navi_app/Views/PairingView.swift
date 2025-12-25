import SwiftUI

struct PairingView: View {
    @State private var showCreateCode = false
    @State private var showJoinCode = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Pair with Partner")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Connect with your partner to start sending taps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    showCreateCode = true
                } label: {
                    Label("Create Code", systemImage: "plus.circle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    showJoinCode = true
                } label: {
                    Label("Join with Code", systemImage: "arrow.right.circle")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
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
    PairingView()
        .environmentObject(PairingManager())
}
