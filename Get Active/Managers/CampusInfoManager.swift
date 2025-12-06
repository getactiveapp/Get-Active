import Foundation

struct BuildingInfo {
    let name: String
    let hours: String
    let description: String?
}

class CampusInfoManager {
    static let shared = CampusInfoManager()
    
    // Central State University campus buildings and hours
    let buildings: [BuildingInfo] = [
        BuildingInfo(
            name: "Hallie Q. Brown Memorial Library",
            hours: "Monday-Thursday: 8:00 AM - 9:00 PM, Friday: 8:00 AM - 5:00 PM, Saturday: 10:00 AM - 4:00 PM, Sunday: 2:00 PM - 9:00 PM",
            description: "Main library building"
        ),
        BuildingInfo(
            name: "Student Center",
            hours: "Monday-Friday: 7:00 AM - 10:00 PM, Saturday-Sunday: 9:00 AM - 8:00 PM",
            description: "Student activities and dining"
        ),
        BuildingInfo(
            name: "Recreation Center",
            hours: "Monday-Friday: 6:00 AM - 10:00 PM, Saturday-Sunday: 9:00 AM - 8:00 PM",
            description: "Gym and fitness facilities"
        ),
        BuildingInfo(
            name: "Administration Building",
            hours: "Monday-Friday: 8:00 AM - 5:00 PM, Closed weekends",
            description: "Main administration offices"
        ),
        BuildingInfo(
            name: "Academic Building",
            hours: "Monday-Friday: 7:00 AM - 9:00 PM, Saturday: 9:00 AM - 3:00 PM, Closed Sunday",
            description: "Classrooms and academic offices"
        ),
        BuildingInfo(
            name: "Science Building",
            hours: "Monday-Friday: 7:00 AM - 9:00 PM, Saturday: 9:00 AM - 3:00 PM, Closed Sunday",
            description: "Science labs and classrooms"
        ),
        BuildingInfo(
            name: "Fine Arts Building",
            hours: "Monday-Friday: 8:00 AM - 8:00 PM, Saturday: 10:00 AM - 4:00 PM, Closed Sunday",
            description: "Music, art, and performing arts"
        ),
        BuildingInfo(
            name: "Residence Halls",
            hours: "24/7 access for residents",
            description: "Student housing"
        ),
        BuildingInfo(
            name: "Campus Yard",
            hours: "Open 24/7",
            description: "Outdoor common area and event space"
        ),
        BuildingInfo(
            name: "Dining Hall",
            hours: "Monday-Friday: 7:00 AM - 8:00 PM, Saturday-Sunday: 10:00 AM - 7:00 PM",
            description: "Campus dining facility"
        ),
        BuildingInfo(
            name: "Campus Chapel",
            hours: "Monday-Friday: 8:00 AM - 6:00 PM, Saturday-Sunday: 10:00 AM - 4:00 PM",
            description: "Religious services and prayer space"
        ),
        BuildingInfo(
            name: "Athletic Center",
            hours: "Monday-Friday: 6:00 AM - 10:00 PM, Saturday-Sunday: 9:00 AM - 8:00 PM",
            description: "Athletic facilities and sports"
        ),
        BuildingInfo(
            name: "Health Center",
            hours: "Monday-Friday: 8:00 AM - 5:00 PM, Closed weekends",
            description: "Student health services"
        )
    ]
    
    func getBuildingHours(for buildingName: String) -> String? {
        let lowercased = buildingName.lowercased()
        return buildings.first { building in
            building.name.lowercased().contains(lowercased) || lowercased.contains(building.name.lowercased())
        }?.hours
    }
    
    func getAllBuildingsInfo() -> String {
        var info = "Campus Buildings at Central State University:\n\n"
        for building in buildings {
            info += "• \(building.name)\n  Hours: \(building.hours)\n"
            if let description = building.description {
                info += "  (\(description))\n"
            }
            info += "\n"
        }
        return info
    }
    
    func getBuildingsJSON() -> String {
        let buildingsData = buildings.map { building in
            [
                "name": building.name,
                "hours": building.hours,
                "description": building.description ?? ""
            ]
        }
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: buildingsData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return "[]"
    }
}

