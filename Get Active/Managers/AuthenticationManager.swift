import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var requires2FA: Bool = false
    @Published var pending2FAUserId: String?
    @Published var pending2FAEmail: String?
    
    // Configuration: Set to true to use Firebase, false for local storage
    private let useFirebase: Bool = true // Change to false to use local storage
    
    private let usersKey = "saved_users"
    private let currentUserIdKey = "current_user_id"
    private let passwordHasher = PasswordHasher.shared
    private let secureKeyManager = SecureKeyManager.shared
    private let firebaseService = FirebaseService.shared
    private let emailService = EmailService.shared
    
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
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.saveCurrentUserId(user.id)
                        completion(true, nil)
                    case .failure(let error):
                        completion(false, error.localizedDescription)
                    }
                }
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
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let user):
                            // Require 2FA for all users
                            self?.requires2FA = true
                            self?.pending2FAUserId = user.id
                            self?.pending2FAEmail = user.email
                            completion(false, "2FA_REQUIRED")
                        case .failure(let error):
                            completion(false, error.localizedDescription)
                        }
                    }
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
        currentUser = user
        isAuthenticated = true
        saveCurrentUserId(user.id)
        requires2FA = false
        pending2FAUserId = nil
        pending2FAEmail = nil
        
        // Save auth token to Keychain (for future API integration)
        let token = UUID().uuidString
        secureKeyManager.saveAuthToken(token)
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
            firebaseService.getCurrentUser { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        // Clear 2FA code
                        self?.secureKeyManager.delete2FACode()
                        // Complete login
                        self?.completeLogin(user: user)
                        completion(true, nil)
                    case .failure(let error):
                        completion(false, error.localizedDescription)
                    }
                }
            }
        } else {
            let users = loadUsers()
            guard let user = users.first(where: { $0.id == userId }) else {
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
        emailService.send2FACode(to: userEmail, code: code) { result in
            switch result {
            case .success:
                completion(true, nil) // Don't return code in production
            case .failure(let error):
                // If email service fails, still save code but log error
                print("⚠️ Failed to send email: \(error.localizedDescription)")
                // For development, return code if email fails
                #if DEBUG
                completion(true, code) // Only in debug mode
                #else
                completion(false, "Failed to send verification code. Please try again.")
                #endif
            }
        }
    }
    
    func logout() {
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
    
    func updateUser(_ user: User) {
        if useFirebase {
            firebaseService.updateUser(user) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.currentUser = user
                        self?.saveCurrentUserId(user.id)
                    case .failure(let error):
                        print("Error updating user: \(error.localizedDescription)")
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
    func login(accountType: AccountType) {
        // This is kept for backward compatibility but should not be used
        // Create a demo user based on account type
        let demoUser = User(
            email: "demo@example.com",
            username: "demo_user",
            password: "demo",
            name: "Jalen Martin",
            university: "Central State University",
            year: "Senior",
            profileImageName: nil,
            bio: "",
            accountType: accountType,
            friends: ["friend1", "friend2", "friend3", "friend4"],
            favoriteEventIds: []
        )
        
        currentUser = demoUser
        isAuthenticated = true
    }
}
