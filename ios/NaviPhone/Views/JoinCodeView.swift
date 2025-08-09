import SwiftUI

struct JoinCodeView: View {
    @EnvironmentObject var pairingManager: PairingManager
    @Environment(\.dismiss) var dismiss
    @State private var codeDigits = Array(repeating: "", count: 6)
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var focusedField: Int?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 20) {
                    Text("Enter Partner's Code")
                        .font(.headline)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<6) { index in
                            TextField("", text: $codeDigits[index])
                                .font(.system(size: 32, weight: .bold, design: .monospaced))
                                .multilineTextAlignment(.center)
                                .frame(width: 45, height: 60)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                                .focused($focusedField, equals: index)
                                .keyboardType(.numberPad)
                                .onChange(of: codeDigits[index]) { newValue in
                                    handleDigitChange(at: index, newValue: newValue)
                                }
                        }
                    }
                }
                .padding(.top, 60)
                
                if showError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await joinWithCode()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Join")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isCodeComplete ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(!isCodeComplete || isLoading)
                .padding(.horizontal, 40)
            }
            .padding()
            .navigationTitle("Join Pairing")
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
            focusedField = 0
        }
    }
    
    private var isCodeComplete: Bool {
        codeDigits.allSatisfy { !$0.isEmpty }
    }
    
    private var fullCode: String {
        codeDigits.joined()
    }
    
    private func handleDigitChange(at index: Int, newValue: String) {
        if newValue.count > 1 {
            codeDigits[index] = String(newValue.last!)
        }
        
        if !newValue.isEmpty && index < 5 {
            focusedField = index + 1
        } else if newValue.isEmpty && index > 0 {
            focusedField = index - 1
        }
    }
    
    private func joinWithCode() async {
        isLoading = true
        showError = false
        
        let success = await pairingManager.joinWithCode(fullCode)
        
        if success {
            dismiss()
        } else {
            errorMessage = "Invalid or expired code"
            showError = true
        }
        
        isLoading = false
    }
}