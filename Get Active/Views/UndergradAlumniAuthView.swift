import SwiftUI

struct UndergradAlumniAuthView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: AuthTab = .login
    @State private var university: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showing2FA = false
    
    enum AuthTab {
        case login
        case signUp
    }
    
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
                    Text("Undergrad/Alumni")
                        .font(.system(size: DeviceSize.isPad ? 40 : 28, weight: .bold))
                        .foregroundColor(.getActiveRed)
                    Spacer()
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 6)
                
                // Subtitle
                HStack {
                    Text("Join your campus community")
                        .font(.system(size: DeviceSize.isPad ? 20 : 14, weight: .regular))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, 2)
                
                // Tabs
                HStack(spacing: DeviceSize.isPad ? 40 : 30) {
                    Button(action: {
                        withAnimation {
                            selectedTab = .login
                            clearFields()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("Log In")
                                .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                                .foregroundColor(selectedTab == .login ? .white : .gray)
                            
                            if selectedTab == .login {
                                Rectangle()
                                    .fill(Color.getActiveRed)
                                    .frame(height: 2)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                            }
                        }
                    }
                    
                    Button(action: {
                        withAnimation {
                            selectedTab = .signUp
                            clearFields()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text("Sign Up")
                                .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                                .foregroundColor(selectedTab == .signUp ? .white : .gray)
                            
                            if selectedTab == .signUp {
                                Rectangle()
                                    .fill(Color.getActiveRed)
                                    .frame(height: 2)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 2)
                            }
                        }
                    }
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 10)
                
                // Form
                ScrollView {
                    VStack(spacing: DeviceSize.isPad ? 20 : 12) {
                        // University (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("University (Optional)")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("e.g. Central State University", text: $university)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        if selectedTab == .signUp {
                            // Email (Sign Up only)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Email")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("*")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.getActiveRed)
                                }
                                
                                TextField("your.email@example.com", text: $email)
                                    .font(.system(size: DeviceSize.bodyFontSize))
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, DeviceSize.isPad ? 16 : 10)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Username
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Username")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                Text("*")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.getActiveRed)
                            }
                            
                            TextField(selectedTab == .login ? "Enter your username" : "Choose a username", text: $username)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Password")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                Text("*")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.getActiveRed)
                            }
                            
                            SecureField(selectedTab == .login ? "Enter your password" : "Create a password", text: $password)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, DeviceSize.isPad ? 20 : 10)
                    .padding(.bottom, DeviceSize.isPad ? 20 : 10)
                }
                
                // Action Button
                Button(action: {
                    handleAuth()
                }) {
                    Text(selectedTab == .login ? "Log In" : "Sign Up")
                        .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DeviceSize.isPad ? 60 : 50)
                        .background(Color.getActiveRed)
                        .cornerRadius(12)
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 6)
                .padding(.bottom, DeviceSize.isPad ? 30 : 16)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .fullScreenCover(isPresented: $showing2FA) {
            TwoFactorAuthView()
                .environmentObject(authManager)
        }
    }
    
    private func clearFields() {
        university = ""
        email = ""
        username = ""
        password = ""
        errorMessage = nil
    }
    
    private func handleAuth() {
        isLoading = true
        errorMessage = nil
        
        if selectedTab == .login {
            authManager.login(username: username, password: password, university: university.isEmpty ? nil : university) { success, error in
                isLoading = false
                if success {
                    dismiss()
                } else if error == "2FA_REQUIRED" {
                    // Show 2FA screen
                    showing2FA = true
                } else {
                    errorMessage = error ?? "Login failed"
                    showingError = true
                }
            }
        } else {
            authManager.signUp(email: email, username: username, password: password, university: university.isEmpty ? nil : university, accountType: .undergradAlumni) { success, error in
                isLoading = false
                if success {
                    dismiss()
                } else {
                    errorMessage = error ?? "Sign up failed"
                    showingError = true
                }
            }
        }
    }
}

#Preview {
    UndergradAlumniAuthView()
        .environmentObject(AuthenticationManager())
}
