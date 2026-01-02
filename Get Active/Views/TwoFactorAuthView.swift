import SwiftUI

struct TwoFactorAuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var code: String = ""
    @State private var isLoading = false
    @State private var isSendingCode = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var codeSent = false
    @State private var sentCode: String? // For demo - remove in production
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 6)
                
                // Title
                HStack {
                    Text("Two-Factor Authentication")
                        .font(.system(size: DeviceSize.isPad ? 40 : 28, weight: .bold))
                        .foregroundColor(.getActiveRed)
                    Spacer()
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 10)
                
                // Subtitle
                HStack {
                    Text("Enter the verification code sent to your email")
                        .font(.system(size: DeviceSize.isPad ? 20 : 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, 8)
                
                Spacer()
                
                // Code Input
                VStack(spacing: 20) {
                    Text("Verification Code")
                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                        .foregroundColor(.white)
                    
                    TextField("000000", text: $code)
                        .font(.system(size: DeviceSize.isPad ? 32 : 28, weight: .bold))
                        .foregroundColor(.white)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, DeviceSize.isPad ? 20 : 16)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(12)
                        .frame(maxWidth: 200)
                    
                    // Demo code display (remove in production)
                    if let demoCode = sentCode {
                        VStack(spacing: 8) {
                            Text("Demo Code (remove in production):")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.gray)
                            Text(demoCode)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.getActiveRed)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Resend Code Button
                    Button(action: {
                        sendCode()
                    }) {
                        Text("Resend Code")
                            .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                            .foregroundColor(.getActiveRed)
                    }
                    .disabled(isSendingCode)
                    .opacity(isSendingCode ? 0.6 : 1.0)
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                
                Spacer()
                
                // Verify Button
                Button(action: {
                    verifyCode()
                }) {
                    Text("Verify")
                        .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DeviceSize.isPad ? 60 : 50)
                        .background(code.count == 6 ? Color.getActiveRed : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(code.count != 6 || isLoading)
                .opacity(isLoading ? 0.6 : 1.0)
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.bottom, DeviceSize.isPad ? 30 : 20)
            }
        }
        .onAppear {
            if !codeSent {
                sendCode()
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }
    
    private func sendCode() {
        isSendingCode = true
        authManager.send2FACode { success, code in
            isSendingCode = false
            if success {
                codeSent = true
                // For demo - remove in production
                if let demoCode = code {
                    sentCode = demoCode
                }
            } else {
                errorMessage = code ?? "Failed to send verification code"
                showingError = true
            }
        }
    }
    
    private func verifyCode() {
        guard code.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        
        authManager.verify2FA(code: code) { success, error in
            isLoading = false
            if success {
                dismiss()
            } else {
                errorMessage = error ?? "Invalid verification code"
                showingError = true
                code = "" // Clear code on error
            }
        }
    }
}

#Preview {
    TwoFactorAuthView()
        .environmentObject(AuthenticationManager())
}
