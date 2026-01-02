import Foundation

struct DiscoverableProfile: Identifiable, Codable {
    let id: String
    var name: String
    var profileImageName: String?
    var major: String
    var location: String // University name
    var year: String
    var bio: String
    var interests: [String]
    
    init(id: String = UUID().uuidString, name: String, profileImageName: String? = nil, major: String, location: String, year: String, bio: String, interests: [String] = []) {
        self.id = id
        self.name = name
        self.profileImageName = profileImageName
        self.major = major
        self.location = location
        self.year = year
        self.bio = bio
        self.interests = interests
    }
}
