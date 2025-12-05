import Foundation
import CoreLocation

struct University: Identifiable, Codable {
    let id: String
    var name: String
    var abbreviation: String
    var location: CLLocationCoordinate2D
    var distance: Double // in miles
    var eventCount: Int
    
    init(id: String = UUID().uuidString, name: String, abbreviation: String, location: CLLocationCoordinate2D, distance: Double, eventCount: Int) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.location = location
        self.distance = distance
        self.eventCount = eventCount
    }
}

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }
}

