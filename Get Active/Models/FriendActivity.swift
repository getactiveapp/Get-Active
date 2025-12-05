import Foundation

struct FriendActivity: Identifiable {
    let id: String
    let friendId: String
    let friendName: String
    let friendImageName: String?
    let activityType: ActivityType
    let eventId: String
    let eventTitle: String
    let timestamp: Date
    
    enum ActivityType {
        case going
        case liked
    }
}

