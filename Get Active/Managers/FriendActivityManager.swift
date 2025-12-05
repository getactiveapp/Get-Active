import Foundation

class FriendActivityManager: ObservableObject {
    @Published var activities: [FriendActivity] = []
    
    init() {
        loadSampleActivities()
    }
    
    func loadSampleActivities() {
        let calendar = Calendar.current
        
        activities = [
            FriendActivity(
                id: "1",
                friendId: "friend1",
                friendName: "Ray",
                friendImageName: "ray_profile",
                activityType: .going,
                eventId: "event3",
                eventTitle: "Campus Music Festival",
                timestamp: calendar.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            ),
            FriendActivity(
                id: "2",
                friendId: "friend2",
                friendName: "Isabella",
                friendImageName: "isabella_profile",
                activityType: .liked,
                eventId: "event4",
                eventTitle: "Career Fair",
                timestamp: calendar.date(byAdding: .hour, value: -5, to: Date()) ?? Date()
            )
        ]
    }
}

