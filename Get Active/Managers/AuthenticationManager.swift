import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    private let usersKey = "saved_users"
    private let currentUserIdKey = "current_user_id"
    
    init() {
        // Check for saved login on initialization
        checkForSavedLogin()
    }
    
    // MARK: - User Storage
    
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
            password: hashedPassword, // Stored as hash
            name: username, // Default name to username
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
    
    func login(username: String, password: String, university: String?, completion: @escaping (Bool, String?) -> Void) {
        guard !username.isEmpty, !password.isEmpty else {
            completion(false, "Please enter your username and password")
            return
        }
        
        let users = loadUsers()
        
        // Find user by username (case-insensitive)
        if let user = users.first(where: { $0.username.lowercased() == username.lowercased() && $0.password == password }) {
            currentUser = user
            isAuthenticated = true
            saveCurrentUserId(user.id)
            completion(true, nil)
        } else {
            completion(false, "Invalid username or password")
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        saveCurrentUserId(nil)
        requires2FA = false
        pending2FAUserId = nil
        
        // Clear all secure tokens
        secureKeyManager.clearAll()
    }
    
    func deleteAccount(completion: @escaping (Bool) -> Void) {
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
    
    func updateUser(_ user: User) {
        var users = loadUsers()
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = user
            saveUsers(users)
            currentUser = user
            saveCurrentUserId(user.id)
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
