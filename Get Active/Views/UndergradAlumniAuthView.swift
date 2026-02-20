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
                        
                        // Email (Required for both login and sign-up)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Email")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                Text("*")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.getActiveRed)
                            }
                            
                            TextField(selectedTab == .login ? "your.email@example.com" : "your.email@example.com", text: $email)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        // Username (Sign-up only - for custom display name)
                        if selectedTab == .signUp {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Username")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("*")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.getActiveRed)
                                }
                                
                                TextField("Choose a username", text: $username)
                                    .font(.system(size: DeviceSize.bodyFontSize))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }
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
                    print("🔵 Undergrad/Alumni button tapped. Selected tab: \(selectedTab)")
                    handleAuth()
                }) {
                    Text(selectedTab == .login ? "Log In" : "Sign Up")
                        .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DeviceSize.isPad ? 60 : 50)
                        .background(isFormValid ? Color.getActiveRed : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(isLoading)
                .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
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
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            // Auto-dismiss when authentication succeeds
            if isAuthenticated {
                dismiss()
            }
        }
    }
    
    private var isFormValid: Bool {
        if selectedTab == .login {
            // Login: need email and password
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
        } else {
            // Sign-up: need email, username, and password
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedEmail.isEmpty && !trimmedUsername.isEmpty && !password.isEmpty
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
        print("🔵 handleAuth called. Selected tab: \(selectedTab)")
        
        // Check form validity first and show error if invalid
        if !isFormValid {
            if selectedTab == .login {
                if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    errorMessage = "Please enter your email"
                } else if password.isEmpty {
                    errorMessage = "Please enter your password"
                }
            } else {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmedEmail.isEmpty {
                    errorMessage = "Please enter your email"
                } else if trimmedUsername.isEmpty {
                    errorMessage = "Please enter a username"
                } else if password.isEmpty {
                    errorMessage = "Please enter a password"
                }
            }
            showingError = true
            print("❌ Form validation failed")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        if selectedTab == .login {
            // Use email for login (not username)
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 Undergrad/Alumni login with email: \(trimmedEmail)")
            
            authManager.login(username: trimmedEmail, password: password, university: university.isEmpty ? nil : university) { success, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        print("✅ Undergrad/Alumni login successful")
                        self.dismiss()
                    } else if error == "2FA_REQUIRED" {
                        // Show 2FA screen
                        self.showing2FA = true
                    } else {
                        let errorMsg = error ?? "Login failed"
                        print("❌ Login error: \(errorMsg)")
                        self.errorMessage = errorMsg
                        self.showingError = true
                    }
                }
            }
        } else {
            // Sign-up
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("📝 Undergrad/Alumni sign-up with email: \(trimmedEmail), username: \(trimmedUsername)")
            
            authManager.signUp(email: trimmedEmail, username: trimmedUsername, password: password, university: university.isEmpty ? nil : university, accountType: .undergradAlumni) { success, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        print("✅ Undergrad/Alumni sign-up successful - automatically navigating to Home Screen")
                        // Dismiss auth view - ContentView will automatically show MainTabView
                        // since isAuthenticated is now true and pendingActiveMemberPayment is false
                        self.dismiss()
                    } else {
                        let errorMsg = error ?? "Sign up failed"
                        print("❌ Sign-up error: \(errorMsg)")
                        self.errorMessage = errorMsg
                        self.showingError = true
                    }
                }
            }
        }
    }
}
