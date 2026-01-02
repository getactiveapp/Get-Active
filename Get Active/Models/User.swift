import Foundation

enum AccountType: String, Codable {
    case activeMember
    case undergradAlumni
}

struct User: Identifiable, Codable {
    let id: String
    var name: String
    var university: String
    var year: String
    var profileImageName: String?
    var bio: String
    var accountType: AccountType
    var friends: [String] // Friend IDs
    var favoriteEventIds: [String]
    var friendFinderImageName: String? // Image for Friend Finder profile
    var friendFinderDescription: String // Personal description for Friend Finder
    var notificationAdvanceMinutes: Int // Minutes before event to send notification (15, 30, or 50)
    
    init(id: String = UUID().uuidString, name: String, university: String, year: String, profileImageName: String? = nil, bio: String = "", accountType: AccountType, friends: [String] = [], favoriteEventIds: [String] = [], friendFinderImageName: String? = nil, friendFinderDescription: String = "", notificationAdvanceMinutes: Int = 30) {
        self.id = id
        self.name = name
        self.university = university
        self.year = year
        self.profileImageName = profileImageName
        self.bio = bio
        self.accountType = accountType
        self.friends = friends
        self.favoriteEventIds = favoriteEventIds
        self.friendFinderImageName = friendFinderImageName
        self.friendFinderDescription = friendFinderDescription
        self.notificationAdvanceMinutes = notificationAdvanceMinutes
    }
}

