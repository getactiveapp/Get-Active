import Foundation
import FirebaseFirestore

class FriendActivityManager: ObservableObject {
    @Published var activities: [FriendActivity] = []
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRemovable] = []
    
    init() {
        // Activities will be loaded from Firebase when user logs in
    }
    
    /// Load friend activities from Firebase
    func loadActivities(for userId: String) {
        // Clear existing listeners
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        
        // Get user's friends list
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            guard let self = self,
                  let data = document?.data(),
                  let friendIds = data["friends"] as? [String] else {
                self?.activities = []
                return
            }
            
            // Load activities for each friend
            for friendId in friendIds {
                self.loadActivitiesForFriend(friendId: friendId)
            }
        }
    }
    
    private func loadActivitiesForFriend(friendId: String) {
        // Listen to events this friend is attending or has liked
        // This would require tracking friend interactions in Firestore
        // For now, activities will be empty until real data is available
    }
    
    func removeListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
}

