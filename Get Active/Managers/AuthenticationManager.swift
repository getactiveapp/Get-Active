import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    
    func login(accountType: AccountType) {
        // Create a demo user based on account type
        let demoUser = User(
            name: "Jalen Martin",
            university: "Central State University",
            year: "Senior",
            profileImageName: "profile_jalen",
            accountType: accountType,
            friends: ["friend1", "friend2", "friend3", "friend4"],
            favoriteEventIds: [] // Will be populated after events are loaded
        )
        
        currentUser = demoUser
        isAuthenticated = true
    }
    
    // Removed automatic initialization - favorites are now only added when user explicitly likes an event
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
    }
}

