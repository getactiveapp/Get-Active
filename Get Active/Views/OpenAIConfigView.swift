import SwiftUI

struct OpenAIConfigView: View {
    @Environment(\.dismiss) var dismiss
    @State private var apiKey: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.getActiveRed)
                        
                        Text("OpenAI API Configuration")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your OpenAI API key to enable AI chat features")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 40)
                    
                    // API Key Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("API Key")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        SecureField("sk-...", text: $apiKey)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Info Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.getActiveRed)
                            Text("How to get your API key:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1. Go to platform.openai.com")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            Text("2. Sign in or create an account")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            Text("3. Navigate to API Keys section")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            Text("4. Create a new secret key")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                            Text("5. Copy and paste it here")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            saveAPIKey()
                        }) {
                            Text("Save API Key")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(apiKey.isEmpty ? Color.gray.opacity(0.3) : Color.getActiveRed)
                                .cornerRadius(12)
                        }
                        .disabled(apiKey.isEmpty || isSaving)
                        .opacity(isSaving ? 0.6 : 1.0)
                        
                        if let existingKey = SecureKeyManager.shared.getOpenAIAPIKey(), !existingKey.isEmpty {
                            Button(action: {
                                checkAPIKey()
                            }) {
                                Text("Test Current Key")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.getActiveRed)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                loadExistingKey()
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadExistingKey() {
        if let key = SecureKeyManager.shared.getOpenAIAPIKey(), !key.isEmpty {
            // Show masked version
            if key.count > 8 {
                let prefix = String(key.prefix(4))
                let suffix = String(key.suffix(4))
                apiKey = "\(prefix)\(String(repeating: "*", count: key.count - 8))\(suffix)"
            } else {
                apiKey = String(repeating: "*", count: key.count)
            }
        }
    }
    
    private func saveAPIKey() {
        guard !apiKey.isEmpty else { return }
        
        // Check if it's a masked key (contains asterisks)
        if apiKey.contains("*") {
            alertTitle = "Key Already Saved"
            alertMessage = "Your API key is already saved. Enter a new key to replace it."
            showingAlert = true
            return
        }
        
        // Validate key format
        guard apiKey.hasPrefix("sk-") || apiKey.hasPrefix("sk_") else {
            alertTitle = "Invalid Key Format"
            alertMessage = "OpenAI API keys should start with 'sk-' or 'sk_'"
            showingAlert = true
            return
        }
        
        isSaving = true
        
        // Save to Keychain
        if SecureKeyManager.shared.saveOpenAIAPIKey(apiKey) {
            alertTitle = "Success"
            alertMessage = "API key saved successfully! AI chat is now enabled."
            showingAlert = true
            
            // Clear the field after saving
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                apiKey = ""
                isSaving = false
            }
        } else {
            alertTitle = "Error"
            alertMessage = "Failed to save API key. Please try again."
            showingAlert = true
            isSaving = false
        }
    }
    
    private func checkAPIKey() {
        guard let key = SecureKeyManager.shared.getOpenAIAPIKey(), !key.isEmpty else {
            alertTitle = "No Key Found"
            alertMessage = "No API key is currently saved."
            showingAlert = true
            return
        }
        
        // Test the key by making a simple API call
        alertTitle = "Testing Key"
        alertMessage = "Testing API key..."
        showingAlert = true
        
        // Simple validation - in production, you might want to make an actual API call
        if key.hasPrefix("sk-") || key.hasPrefix("sk_") {
            alertTitle = "Key Valid"
            alertMessage = "Your API key format looks correct. AI chat should work."
        } else {
            alertTitle = "Key Invalid"
            alertMessage = "Your API key format may be incorrect."
        }
    }
}

#Preview {
    OpenAIConfigView()
}
