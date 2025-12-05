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
    var accountType: AccountType
    var friends: [String] // Friend IDs
    var favoriteEventIds: [String]
    
    init(id: String = UUID().uuidString, name: String, university: String, year: String, profileImageName: String? = nil, accountType: AccountType, friends: [String] = [], favoriteEventIds: [String] = []) {
        self.id = id
        self.name = name
        self.university = university
        self.year = year
        self.profileImageName = profileImageName
        self.accountType = accountType
        self.friends = friends
        self.favoriteEventIds = favoriteEventIds
    }
}

