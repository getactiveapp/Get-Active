import SwiftUI

struct ActiveMemberAuthView: View {
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
    @State private var showingApplication = false
    @State private var showingPayment = false
    
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
                    Text("Active Member")
                        .font(.system(size: DeviceSize.isPad ? 40 : 28, weight: .bold))
                        .foregroundColor(.getActiveRed)
                    Spacer()
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 6)
                
                // Subtitle
                HStack {
                    Text("Premium event creation & analytics")
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
                .padding(.top, DeviceSize.isPad ? 20 : 12)
                
                // Form
                ScrollView {
                    VStack(spacing: DeviceSize.isPad ? 20 : 14) {
                        // University (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("University (Optional)")
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                .foregroundColor(.white)
                            
                            TextField("e.g. Central State University", text: $university)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                        
                        // School Email (Required for both login and sign-up)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("School Email")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                Text("*")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                    .foregroundColor(.getActiveRed)
                            }
                            
                            TextField(selectedTab == .login ? "your.email@university.edu" : "your.email@university.edu", text: $email)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding(.horizontal, 16)
                                .padding(.vertical, DeviceSize.isPad ? 16 : 10)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            
                            if selectedTab == .signUp && !email.isEmpty && !email.lowercased().hasSuffix(".edu") {
                                Text("Please enter a valid school email ending in .edu")
                                    .font(.system(size: DeviceSize.captionFontSize))
                                    .foregroundColor(.getActiveRed)
                                    .padding(.top, 4)
                            }
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
                                .padding(.vertical, DeviceSize.isPad ? 16 : 12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, DeviceSize.isPad ? 20 : 16)
                    .padding(.bottom, DeviceSize.isPad ? 20 : 16)
                }
                
                // Action Button
                Button(action: {
                    print("🔵 🔵 🔵 BUTTON TAPPED! Selected tab: \(selectedTab), Form valid: \(isFormValid)")
                    print("🔵 Email: '\(email)', Username: '\(username)', Password length: \(password.count)")
                    print("🔵 IsLoading: \(isLoading)")
                    if isLoading {
                        print("⚠️ Button is disabled due to loading state")
                        return
                    }
                    handleAuth()
                }) {
                    Text(selectedTab == .login ? "Log In" : "Sign Up")
                        .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DeviceSize.isPad ? 60 : 55)
                        .background(isFormValid ? Color.getActiveRed : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(isLoading)
                .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 12)
                .padding(.bottom, DeviceSize.isPad ? 30 : 20)
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
        .fullScreenCover(isPresented: $showingApplication) {
            ActiveMemberApplicationView {
                // After application is submitted, show payment screen
                print("🔵 Application completed, showing payment screen")
                showingApplication = false
                showingPayment = true
            }
            .environmentObject(authManager)
            .onAppear {
                print("✅ ActiveMemberApplicationView appeared!")
            }
        }
        .onChange(of: showingApplication) { newValue in
            print("🔵 showingApplication changed to: \(newValue)")
        }
        .onChange(of: showingPayment) { newValue in
            print("🔵 showingPayment changed to: \(newValue)")
        }
        .fullScreenCover(isPresented: $showingPayment) {
            ActiveMemberPaymentView {
                // After payment is completed, dismiss and enter app
                showingPayment = false
                dismiss()
            } onSkip: {
                // Skip payment (shouldn't normally happen, but handle it)
                showingPayment = false
                dismiss()
            }
            .environmentObject(authManager)
        }
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            print("🔵 Auth state changed. isAuthenticated: \(isAuthenticated), selectedTab: \(selectedTab), showingPayment: \(showingPayment)")
            // Only auto-dismiss for login, not sign-up (sign-up has its own flow)
            // Also don't dismiss if we're about to show the payment screen
            if isAuthenticated && selectedTab == .login && !showingPayment {
                print("🔵 Auto-dismissing for login")
                dismiss()
            } else if isAuthenticated && selectedTab == .signUp {
                print("🔵 Active Member sign-up authenticated - keeping view open for payment screen")
                // Don't dismiss - we need to show payment screen
            }
        }
    }
    
    private var isFormValid: Bool {
        if selectedTab == .login {
            // Login: need email and password
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
        } else {
            // Sign-up: need email (must end in .edu), username, and password
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            let isValid = !trimmedEmail.isEmpty && trimmedEmail.lowercased().hasSuffix(".edu") && !trimmedUsername.isEmpty && !password.isEmpty
            print("🔵 Form validation check - Email: '\(trimmedEmail)', Username: '\(trimmedUsername)', Password: \(password.isEmpty ? "empty" : "filled"), Valid: \(isValid)")
            return isValid
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
                    errorMessage = "Please enter your school email"
                } else if password.isEmpty {
                    errorMessage = "Please enter your password"
                }
            } else {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if trimmedEmail.isEmpty {
                    errorMessage = "Please enter your school email"
                } else if !trimmedEmail.lowercased().hasSuffix(".edu") {
                    errorMessage = "Please enter a valid school email ending in .edu"
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
            // Validate email for login
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedEmail.isEmpty else {
                isLoading = false
                errorMessage = "Please enter your school email"
                showingError = true
                return
            }
            
            // Use email for login (not username)
            authManager.login(username: trimmedEmail, password: password, university: university.isEmpty ? nil : university) { success, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        // Login successful - dismiss and enter app
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
            // Sign-up validation
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !trimmedEmail.isEmpty else {
                isLoading = false
                errorMessage = "Please enter your school email"
                showingError = true
                return
            }
            
            guard trimmedEmail.lowercased().hasSuffix(".edu") else {
                isLoading = false
                errorMessage = "Please enter a valid school email ending in .edu"
                showingError = true
                return
            }
            
            guard !trimmedUsername.isEmpty else {
                isLoading = false
                errorMessage = "Please enter a username"
                showingError = true
                return
            }
            
            guard !password.isEmpty else {
                isLoading = false
                errorMessage = "Please enter a password"
                showingError = true
                return
            }
            
            print("📝 Starting Active Member sign-up with email: \(trimmedEmail), username: \(trimmedUsername)")
            
            authManager.signUp(email: trimmedEmail, username: trimmedUsername, password: password, university: university.isEmpty ? nil : university, accountType: .activeMember) { success, error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    if success {
                        print("✅ Active Member sign-up successful - automatically navigating to Payment Screen")
                        // Dismiss auth view - ContentView will automatically show payment screen
                        // since isAuthenticated is now true and pendingActiveMemberPayment is true
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

#Preview {
    ActiveMemberAuthView()
        .environmentObject(AuthenticationManager())
}


