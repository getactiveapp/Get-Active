import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var requires2FA: Bool = false
    @Published var pending2FAUserId: String?
    @Published var pending2FAEmail: String?
    @Published var pendingActiveMemberPayment: Bool = false // Flag to show payment screen for Active Members after sign-up
    @Published var pendingActiveMemberApplication: Bool = false // Flag to show application screen for Active Members after sign-up
    private var pendingAuthenticatedUser: User? // Store user after Firebase login, before 2FA
    
    // Configuration: Set to true to use Firebase, false for local storage
    private let useFirebase: Bool = true // Change to false to use local storage
    
    private let usersKey = "saved_users"
    private let currentUserIdKey = "current_user_id"
    private let passwordHasher = PasswordHasher.shared
    private let secureKeyManager = SecureKeyManager.shared
    private let firebaseService = FirebaseService.shared
    private let emailService = EmailService.shared
    private let realtimeDB = RealtimeDatabaseService.shared
    
    init() {
        // Check for saved login on initialization
        checkForSavedLogin()
    }
    
    // MARK: - User Storage (Local)
    
    private func saveUsers(_ users: [User]) {
        if let encoded = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(encoded, forKey: usersKey)
        }
    }
    
    private func loadUsers() -> [User] {
        guard let data = UserDefaults.standard.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([User].self, from: data) else {
            return []
        }
        return users
    }
    
    private func saveCurrentUserId(_ userId: String?) {
        UserDefaults.standard.set(userId, forKey: currentUserIdKey)
    }
    
    private func getCurrentUserId() -> String? {
        return UserDefaults.standard.string(forKey: currentUserIdKey)
    }
    
    // MARK: - Authentication
    
    func checkForSavedLogin() {
        if useFirebase {
            // Check Firebase auth state
            firebaseService.getCurrentUser { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.saveCurrentUserId(user.id)
                    case .failure:
                        self?.isAuthenticated = false
                    }
                }
            }
        } else {
            // Local storage check
            guard let userId = getCurrentUserId() else {
                isAuthenticated = false
                return
            }
            
            let users = loadUsers()
            if let user = users.first(where: { $0.id == userId }) {
                currentUser = user
                isAuthenticated = true
            } else {
                isAuthenticated = false
            }
        }
    }
    
    func signUp(email: String, username: String, password: String, university: String?, accountType: AccountType, completion: @escaping (Bool, String?) -> Void) {
        // Validate inputs
        guard !email.isEmpty, !username.isEmpty, !password.isEmpty else {
            completion(false, "Please fill in all required fields")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            completion(false, "Please enter a valid email address")
            return
        }
        
        // For Active Member accounts, require .edu email
        if accountType == .activeMember && !email.lowercased().hasSuffix(".edu") {
            completion(false, "Active Member accounts require a school email ending in .edu")
            return
        }
        
        guard password.count >= 6 else {
            completion(false, "Password must be at least 6 characters")
            return
        }
        
        if useFirebase {
            // Firebase signup
            let userData: [String: Any] = [
                "username": username,
                "name": username,
                "university": university ?? "",
                "year": "",
                "accountType": accountType.rawValue,
                "friends": [],
                "favoriteEventIds": [],
                "bio": "",
                "friendFinderDescription": "",
                "notificationAdvanceMinutes": 30
            ]
            
            firebaseService.signUp(email: email, password: password, userData: userData) { [weak self] result in
                DispatchQueue.main.async(execute: {
                    switch result {
                    case .success(let user):
                        print("✅ Sign-up successful for user: \(user.username) (\(user.email))")
                        // Set user and authentication state
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.saveCurrentUserId(user.id)
                        
                        // For Active Members, set flag to show application screen first, then payment
                        // For Undergrad/Alumni, navigate directly to Home (handled by ContentView)
                        if accountType == .activeMember {
                            print("🔵 Active Member sign-up - setting pendingActiveMemberApplication flag")
                            self?.pendingActiveMemberApplication = true
                            self?.pendingActiveMemberPayment = false
                        } else {
                            print("🔵 Undergrad/Alumni sign-up - navigating to Home Screen")
                            self?.pendingActiveMemberApplication = false
                            self?.pendingActiveMemberPayment = false
                        }
                        
                        completion(true, nil)
                    case .failure(let error):
                        let errorMessage = error.localizedDescription
                        print("❌ Sign-up error: \(errorMessage)")
                        self?.pendingActiveMemberApplication = false
                        self?.pendingActiveMemberPayment = false
                        completion(false, errorMessage)
                    }
                })
            }
        } else {
            // Local storage signup
            var users = loadUsers()
            
            // Check if username already exists
            if users.contains(where: { $0.username.lowercased() == username.lowercased() }) {
                completion(false, "Username already exists")
                return
            }
            
            // Check if email already exists
            if users.contains(where: { $0.email.lowercased() == email.lowercased() }) {
                completion(false, "Email already exists")
                return
            }
            
            // Hash password before storing
            let hashedPassword = passwordHasher.hash(password)
            
            // Create new user
            let newUser = User(
                email: email,
                username: username,
                password: hashedPassword,
                name: username,
                university: university ?? "",
                year: "",
                accountType: accountType,
                friends: [],
                favoriteEventIds: []
            )
            
            users.append(newUser)
            saveUsers(users)
            
            // Auto-login after signup
            currentUser = newUser
            isAuthenticated = true
            saveCurrentUserId(newUser.id)
            
            completion(true, nil)
        }
    }
    
    func login(username: String, password: String, university: String?, completion: @escaping (Bool, String?) -> Void) {
        guard !username.isEmpty, !password.isEmpty else {
            completion(false, "Please enter your username and password")
            return
        }
        
        if useFirebase {
            // Firebase login - try as email first
            if username.contains("@") {
                firebaseService.signIn(email: username, password: password) { [weak self] result in
                    DispatchQueue.main.async(execute: {
                        switch result {
                        case .success(let user):
                            // Store the authenticated user for use after 2FA
                            self?.pendingAuthenticatedUser = user
                            // Require 2FA for all users
                            self?.requires2FA = true
                            self?.pending2FAUserId = user.id
                            self?.pending2FAEmail = user.email
                            completion(false, "2FA_REQUIRED")
                        case .failure(let error):
                            let errorMessage = error.localizedDescription
                            print("❌ Firebase login error: \(errorMessage)")
                            completion(false, errorMessage)
                        }
                    })
                }
            } else {
                // Username login - need to find email first
                // For now, show error - in production, add username-to-email mapping
                completion(false, "Please use your email address to log in")
            }
        } else {
            // Local storage login
            let users = loadUsers()
            
            // Find user by username (case-insensitive)
            guard let user = users.first(where: { $0.username.lowercased() == username.lowercased() }) else {
                completion(false, "Invalid username or password")
                return
            }
            
            // Verify password hash
            guard passwordHasher.verify(password, against: user.password) else {
                completion(false, "Invalid username or password")
                return
            }
            
            // Require 2FA for all users with email
            if user.email.contains("@") {
                requires2FA = true
                pending2FAUserId = user.id
                pending2FAEmail = user.email
                completion(false, "2FA_REQUIRED")
                return
            }
            
            // Complete login
            completeLogin(user: user)
            completion(true, nil)
        }
    }
    
    /// Complete login after 2FA verification
    func completeLogin(user: User) {
        print("✅ Completing login for user: \(user.username) (\(user.email))")
        currentUser = user
        isAuthenticated = true
        saveCurrentUserId(user.id)
        requires2FA = false
        pending2FAUserId = nil
        pending2FAEmail = nil
        pendingAuthenticatedUser = nil
        
        // Save auth token to Keychain (for future API integration)
        let token = UUID().uuidString
        secureKeyManager.saveAuthToken(token)
        
        // Set user as online in Realtime Database (for presence tracking)
        realtimeDB.setUserOnline(userId: user.id)
        
        print("✅ Login completed successfully. User authenticated: \(isAuthenticated)")
    }
    
    /// Verify 2FA code and complete login
    func verify2FA(code: String, completion: @escaping (Bool, String?) -> Void) {
        guard let userId = pending2FAUserId else {
            completion(false, "No pending authentication")
            return
        }
        
        // Verify code from Keychain
        guard let storedCode = secureKeyManager.get2FACode(),
              storedCode == code else {
            completion(false, "Invalid verification code")
            return
        }
        
        // Get user and complete login
        if useFirebase {
            // First try to use the pending authenticated user (from login before 2FA)
            if let pendingUser = pendingAuthenticatedUser {
                // Clear 2FA code
                secureKeyManager.delete2FACode()
                // Complete login with the stored user
                completeLogin(user: pendingUser)
                pendingAuthenticatedUser = nil // Clear after use
                completion(true, nil)
                return
            }
            
            // Fallback: Try to get current user from Firebase
            firebaseService.getCurrentUser { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        // Clear 2FA code
                        self?.secureKeyManager.delete2FACode()
                        // Complete login
                        self?.completeLogin(user: user)
                        self?.pendingAuthenticatedUser = nil // Clear if set
                        completion(true, nil)
                    case .failure(let error):
                        let errorMessage = error.localizedDescription
                        print("❌ Error getting current user after 2FA: \(errorMessage)")
                        completion(false, "Failed to complete login: \(errorMessage)")
                    }
                }
            }
        } else {
            // Local storage login
            let users = loadUsers()
            guard let user = users.first(where: { $0.id == userId }) else {
                print("❌ User not found in local storage: \(userId)")
                completion(false, "User not found")
                return
            }
            
            // Clear 2FA code
            secureKeyManager.delete2FACode()
            
            // Complete login
            completeLogin(user: user)
            completion(true, nil)
        }
    }
    
    /// Send 2FA code (for email-based 2FA)
    func send2FACode(completion: @escaping (Bool, String?) -> Void) {
        guard let email = pending2FAEmail ?? currentUser?.email else {
            completion(false, "No email address found")
            return
        }
        
        send2FACodeToEmail(userEmail: email, completion: completion)
    }
    
    private func send2FACodeToEmail(userEmail: String, completion: @escaping (Bool, String?) -> Void) {
        // Generate 6-digit code
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        
        // Save code to Keychain with 10-minute expiration
        guard secureKeyManager.save2FACode(code, expiresIn: 600) else {
            completion(false, "Failed to generate verification code")
            return
        }
        
        // Send code via email service
        print("📧 Sending 2FA code to email: \(userEmail)")
        print("📧 Email service configured: \(emailService.isConfigured)")
        emailService.send2FACode(to: userEmail, code: code) { result in
            switch result {
            case .success:
                print("✅ 2FA code email sent successfully to: \(userEmail)")
                // Code sent successfully - never return the code to the UI
                completion(true, nil)
            case .failure(let error):
                // If email service fails, log detailed error
                print("❌ Failed to send 2FA email to \(userEmail): \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("   Error domain: \(nsError.domain)")
                    print("   Error code: \(nsError.code)")
                    if let userInfo = nsError.userInfo as? [String: Any] {
                        print("   Error details: \(userInfo)")
                    }
                }
                // Never return the code, even in debug mode, for security
                completion(false, "Failed to send verification code. Please check your email address and try again.")
            }
        }
    }
    
    func logout() {
        // Set user as offline in Realtime Database before logging out
        if let userId = currentUser?.id {
            realtimeDB.setUserOffline(userId: userId)
            realtimeDB.cleanup()
        }
        
        if useFirebase {
            do {
                try firebaseService.signOut()
            } catch {
                print("Error signing out: \(error)")
            }
        }
        
        currentUser = nil
        isAuthenticated = false
        saveCurrentUserId(nil)
        requires2FA = false
        pending2FAUserId = nil
        pending2FAEmail = nil
        
        // Clear all secure tokens
        secureKeyManager.clearAll()
    }
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
        if useFirebase {
            firebaseService.deleteAccount { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.logout()
                        completion(true)
                    case .failure:
                        completion(false)
                    }
                }
            }
        } else {
            guard let userId = currentUser?.id else {
                completion(false)
                return
            }
            
            var users = loadUsers()
            users.removeAll { $0.id == userId }
            saveUsers(users)
            
            logout()
            completion(true)
        }
    }
    
    func updateUser(_ user: User, completion: @escaping (Bool) -> Void = { _ in }) {
        if useFirebase {
            firebaseService.updateUser(user) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.currentUser = user
                        self?.saveCurrentUserId(user.id)
                        completion(true)
                    case .failure(let error):
                        print("Error updating user: \(error.localizedDescription)")
                        completion(false)
                    }
                }
            }
        } else {
            var users = loadUsers()
            if let index = users.firstIndex(where: { $0.id == user.id }) {
                users[index] = user
                saveUsers(users)
                currentUser = user
                saveCurrentUserId(user.id)
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // Convenience method to update current user directly
    func updateCurrentUser(_ updateBlock: (inout User) -> Void) {
        guard var user = currentUser else { return }
        updateBlock(&user)
        updateUser(user)
    }
    
    // Legacy method for backward compatibility
    // REMOVED: Demo user creation - app now uses real Firebase users only
    func login(accountType: AccountType) {
        // This method is deprecated - use login(username:password:university:completion:) instead
        print("⚠️ login(accountType:) is deprecated. Use login(username:password:university:completion:) instead.")
    }
}
