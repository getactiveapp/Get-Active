import Foundation

enum AccountType: String, Codable {
    case activeMember
    case undergradAlumni
}

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var username: String
    var password: String // In production, this should be hashed
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
    var applicationData: [String: Any]? // Application data for Active Member verification
    var isPaymentActive: Bool // Payment status
    var subscriptionStatus: String? // "active", "promo", "expired", etc.
    var subscriptionStartDate: Date? // When subscription started
    
    init(id: String = UUID().uuidString, email: String, username: String, password: String, name: String, university: String, year: String, profileImageName: String? = nil, bio: String = "", accountType: AccountType, friends: [String] = [], favoriteEventIds: [String] = [], friendFinderImageName: String? = nil, friendFinderDescription: String = "", notificationAdvanceMinutes: Int = 30, applicationData: [String: Any]? = nil, isPaymentActive: Bool = false, subscriptionStatus: String? = nil, subscriptionStartDate: Date? = nil) {
        self.id = id
        self.email = email
        self.username = username
        self.password = password
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
        self.applicationData = applicationData
        self.isPaymentActive = isPaymentActive
        self.subscriptionStatus = subscriptionStatus
        self.subscriptionStartDate = subscriptionStartDate
    }
}

// Custom Codable implementation to handle [String: Any] dictionary
extension User {
    enum CodingKeys: String, CodingKey {
        case id, email, username, password, name, university, year
        case profileImageName, bio, accountType, friends, favoriteEventIds
        case friendFinderImageName, friendFinderDescription, notificationAdvanceMinutes
        case applicationData, isPaymentActive, subscriptionStatus, subscriptionStartDate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        name = try container.decode(String.self, forKey: .name)
        university = try container.decode(String.self, forKey: .university)
        year = try container.decode(String.self, forKey: .year)
        profileImageName = try container.decodeIfPresent(String.self, forKey: .profileImageName)
        bio = try container.decode(String.self, forKey: .bio)
        accountType = try container.decode(AccountType.self, forKey: .accountType)
        friends = try container.decode([String].self, forKey: .friends)
        favoriteEventIds = try container.decode([String].self, forKey: .favoriteEventIds)
        friendFinderImageName = try container.decodeIfPresent(String.self, forKey: .friendFinderImageName)
        friendFinderDescription = try container.decode(String.self, forKey: .friendFinderDescription)
        notificationAdvanceMinutes = try container.decode(Int.self, forKey: .notificationAdvanceMinutes)
        
        // Handle applicationData as dictionary
        if let appDataDict = try? container.decode([String: String].self, forKey: .applicationData) {
            applicationData = appDataDict
        } else {
            applicationData = nil
        }
        
        isPaymentActive = try container.decodeIfPresent(Bool.self, forKey: .isPaymentActive) ?? false
        subscriptionStatus = try container.decodeIfPresent(String.self, forKey: .subscriptionStatus)
        subscriptionStartDate = try container.decodeIfPresent(Date.self, forKey: .subscriptionStartDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(name, forKey: .name)
        try container.encode(university, forKey: .university)
        try container.encode(year, forKey: .year)
        try container.encodeIfPresent(profileImageName, forKey: .profileImageName)
        try container.encode(bio, forKey: .bio)
        try container.encode(accountType, forKey: .accountType)
        try container.encode(friends, forKey: .friends)
        try container.encode(favoriteEventIds, forKey: .favoriteEventIds)
        try container.encodeIfPresent(friendFinderImageName, forKey: .friendFinderImageName)
        try container.encode(friendFinderDescription, forKey: .friendFinderDescription)
        try container.encode(notificationAdvanceMinutes, forKey: .notificationAdvanceMinutes)
        
        // Handle applicationData encoding - encode as [String: String] for Codable compatibility
        if let appData = applicationData {
            var appDataString: [String: String] = [:]
            for (key, value) in appData {
                appDataString[key] = "\(value)"
            }
            try container.encode(appDataString, forKey: .applicationData)
        }
        
        try container.encode(isPaymentActive, forKey: .isPaymentActive)
        try container.encodeIfPresent(subscriptionStatus, forKey: .subscriptionStatus)
        try container.encodeIfPresent(subscriptionStartDate, forKey: .subscriptionStartDate)
    }
}

