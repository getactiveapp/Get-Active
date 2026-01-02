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
                        
                        if selectedTab == .signUp {
                            // School Email (Sign Up only)
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("School Email")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.white)
                                    Text("*")
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.getActiveRed)
                                }
                                
                                TextField("your.email@university.edu", text: $email)
                                    .font(.system(size: DeviceSize.bodyFontSize))
                                    .foregroundColor(.white)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, DeviceSize.isPad ? 16 : 10)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                
                                if !email.isEmpty && !email.lowercased().hasSuffix(".edu") {
                                    Text("Please enter a valid school email ending in .edu")
                                        .font(.system(size: DeviceSize.captionFontSize))
                                        .foregroundColor(.getActiveRed)
                                        .padding(.top, 4)
                                }
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
                    handleAuth()
                }) {
                    Text(selectedTab == .login ? "Continue to Payment" : "Continue to Payment")
                        .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DeviceSize.isPad ? 60 : 55)
                        .background(Color.getActiveRed)
                        .cornerRadius(12)
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1.0)
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
                    // For Active Member, after login, proceed to payment
                    // For now, just dismiss (you can add payment flow later)
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
            // Validate school email for sign up
            if !email.lowercased().hasSuffix(".edu") {
                isLoading = false
                errorMessage = "Please enter a valid school email ending in .edu"
                showingError = true
                return
            }
            
            authManager.signUp(email: email, username: username, password: password, university: university.isEmpty ? nil : university, accountType: .activeMember) { success, error in
                isLoading = false
                if success {
                    // For Active Member, after signup, proceed to payment
                    // For now, just dismiss (you can add payment flow later)
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
    ActiveMemberAuthView()
        .environmentObject(AuthenticationManager())
}
