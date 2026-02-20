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
    @State private var userEmail: String = ""
    
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
                VStack(alignment: .leading, spacing: 8) {
                    if codeSent {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Verification code sent!")
                                .font(.system(size: DeviceSize.isPad ? 20 : 14, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text("Enter the verification code sent to your email")
                        .font(.system(size: DeviceSize.isPad ? 20 : 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if !userEmail.isEmpty {
                        Text(userEmail)
                            .font(.system(size: DeviceSize.isPad ? 18 : 14, weight: .medium))
                            .foregroundColor(.getActiveRed)
                    }
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
        .task {
            // Get user email on appear
            if userEmail.isEmpty {
                userEmail = authManager.pending2FAEmail ?? authManager.currentUser?.email ?? ""
            }
            
            // Automatically send code when view appears
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
        errorMessage = nil
        
        // Get user email for display
        if userEmail.isEmpty {
            userEmail = authManager.pending2FAEmail ?? authManager.currentUser?.email ?? ""
        }
        
        authManager.send2FACode { success, errorMessage in
            DispatchQueue.main.async {
                isSendingCode = false
                if success {
                    codeSent = true
                    // Code is sent via email - never display it on screen
                } else {
                    self.errorMessage = errorMessage ?? "Failed to send verification code. Please check your email address and try again."
                    showingError = true
                }
            }
        }
    }
    
    private func verifyCode() {
        guard code.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        
        authManager.verify2FA(code: code) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = error ?? "Invalid verification code. Please check the code sent to your email and try again."
                    showingError = true
                    code = "" // Clear code on error for security
                }
            }
        }
    }
}
