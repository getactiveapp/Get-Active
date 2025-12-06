import Foundation

enum EventCategory: String, Codable, CaseIterable {
    case technology = "Technology"
    case career = "Career"
    case party = "Party"
    case academic = "Academic"
    case vendor = "Vendor"
    case prayer = "Prayer"
    case club = "Club"
    case mentalHealth = "Mental Health"
    case other = "Other"
}

struct Event: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var description: String
    var date: Date
    var startTime: String
    var endTime: String
    var location: String
    var category: EventCategory
    var tags: [String]
    var imageName: String?
    var backgroundColor: String // For gradient/color
    var iconName: String?
    var createdBy: String // User ID
    var likedBy: [String] // User IDs who liked
    var rsvpBy: [String] // User IDs who RSVP'd
    var attending: [String] // User IDs attending
    var isFeatured: Bool
    var customImages: [String]? // Array of image file names for user-uploaded images
    var ratings: [EventRating] = [] // User ratings and feedback
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
    
    init(id: String = UUID().uuidString, title: String, description: String, date: Date, startTime: String, endTime: String, location: String, category: EventCategory, tags: [String] = [], imageName: String? = nil, backgroundColor: String = "red", iconName: String? = nil, createdBy: String, likedBy: [String] = [], rsvpBy: [String] = [], attending: [String] = [], isFeatured: Bool = false, customImages: [String]? = nil, ratings: [EventRating] = []) {
        self.id = id
        self.title = title
        self.description = description
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.category = category
        self.tags = tags
        self.imageName = imageName
        self.backgroundColor = backgroundColor
        self.iconName = iconName
        self.createdBy = createdBy
        self.likedBy = likedBy
        self.rsvpBy = rsvpBy
        self.attending = attending
        self.isFeatured = isFeatured
        self.customImages = customImages
        self.ratings = ratings
    }
}

struct EventRating: Identifiable, Codable {
    let id: String
    let userId: String
    let rating: Int // 1-5 stars
    let feedback: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, userId: String, rating: Int, feedback: String, timestamp: Date = Date()) {
        self.id = id
        self.userId = userId
        self.rating = rating
        self.feedback = feedback
        self.timestamp = timestamp
    }
}

struct EventAnalytics: Codable {
    let eventId: String
    var views: Int
    var likes: Int
    var attendees: Int
    var shares: Int
    var aiFeedback: String
    var ratings: [EventRating] = []
    var averageRating: Double {
        guard !ratings.isEmpty else { return 0.0 }
        let sum = ratings.reduce(0) { $0 + $1.rating }
        return Double(sum) / Double(ratings.count)
    }
}

