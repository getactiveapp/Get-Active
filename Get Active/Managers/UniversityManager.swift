import Foundation
import CoreLocation

class UniversityManager: ObservableObject {
    @Published var nearbyUniversities: [University] = []
    
    // Central State University coordinates (Wilberforce, OH)
    let centralStateLocation = CLLocationCoordinate2D(latitude: 39.7167, longitude: -83.8833)
    
    init() {
        loadNearbyUniversities()
    }
    
    func loadNearbyUniversities() {
        nearbyUniversities = [
            University(
                name: "Wilberforce University",
                abbreviation: "W",
                location: CLLocationCoordinate2D(latitude: 39.7167, longitude: -83.8833),
                distance: 2.1,
                eventCount: 12
            ),
            University(
                name: "Wright State University",
                abbreviation: "W",
                location: CLLocationCoordinate2D(latitude: 39.7844, longitude: -84.0556),
                distance: 8.5,
                eventCount: 15
            ),
            University(
                name: "Ohio State University",
                abbreviation: "O",
                location: CLLocationCoordinate2D(latitude: 40.0067, longitude: -83.0119),
                distance: 45.2,
                eventCount: 28
            ),
            University(
                name: "University of Dayton",
                abbreviation: "U",
                location: CLLocationCoordinate2D(latitude: 39.7406, longitude: -84.1797),
                distance: 25.8,
                eventCount: 18
            ),
            University(
                name: "Wittenberg University",
                abbreviation: "W",
                location: CLLocationCoordinate2D(latitude: 39.9333, longitude: -83.8167),
                distance: 15.3,
                eventCount: 9
            ),
            University(
                name: "Cedarville University",
                abbreviation: "C",
                location: CLLocationCoordinate2D(latitude: 39.8000, longitude: -83.8167),
                distance: 12.7,
                eventCount: 11
            ),
            University(
                name: "University of Cincinnati",
                abbreviation: "U",
                location: CLLocationCoordinate2D(latitude: 39.1322, longitude: -84.5150),
                distance: 55.3,
                eventCount: 22
            )
        ]
    }
}

