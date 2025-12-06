import Foundation

struct MentalHealthResources {
    let wellnessCheckInURL: String
    let mentalHealthResourcesURL: String
    let supportGroupsURL: String
    let crisisSupportPhone: String
    
    static let defaultResources = MentalHealthResources(
        wellnessCheckInURL: "https://mhanational.org/screening-tools",
        mentalHealthResourcesURL: "https://mhanational.org",
        supportGroupsURL: "https://mhanational.org/find-support",
        crisisSupportPhone: "988"
    )
}

class MentalHealthResourcesManager {
    static let shared = MentalHealthResourcesManager()
    
    private var universityResources: [String: MentalHealthResources] = [:]
    
    init() {
        loadUniversityResources()
    }
    
    private func loadUniversityResources() {
        // Central State University
        universityResources["Central State University"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://www.centralstate.edu/student-life/health-services",
            supportGroupsURL: "https://www.centralstate.edu/student-life/counseling-services",
            crisisSupportPhone: "988"
        )
        
        // Wilberforce University
        universityResources["Wilberforce University"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://www.wilberforce.edu/student-life/health-services",
            supportGroupsURL: "https://www.wilberforce.edu/student-life/counseling",
            crisisSupportPhone: "988"
        )
        
        // Wright State University
        universityResources["Wright State University"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://www.wright.edu/campus-life/student-services/counseling-wellness",
            supportGroupsURL: "https://www.wright.edu/campus-life/student-services/counseling-wellness/support-groups",
            crisisSupportPhone: "988"
        )
        
        // Ohio State University
        universityResources["Ohio State University"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://swc.osu.edu/",
            supportGroupsURL: "https://swc.osu.edu/services/support-groups",
            crisisSupportPhone: "988"
        )
        
        // University of Dayton
        universityResources["University of Dayton"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://udayton.edu/studentlife/counseling/",
            supportGroupsURL: "https://udayton.edu/studentlife/counseling/services/support-groups.php",
            crisisSupportPhone: "988"
        )
        
        // Wittenberg University
        universityResources["Wittenberg University"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://www.wittenberg.edu/student-life/health-counseling",
            supportGroupsURL: "https://www.wittenberg.edu/student-life/health-counseling/counseling-services",
            crisisSupportPhone: "988"
        )
        
        // Cedarville University
        universityResources["Cedarville University"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://www.cedarville.edu/Student-Life/Campus-Services/Counseling",
            supportGroupsURL: "https://www.cedarville.edu/Student-Life/Campus-Services/Counseling",
            crisisSupportPhone: "988"
        )
        
        // University of Cincinnati
        universityResources["University of Cincinnati"] = MentalHealthResources(
            wellnessCheckInURL: "https://mhanational.org/screening-tools",
            mentalHealthResourcesURL: "https://www.uc.edu/campus-life/student-affairs/counseling.html",
            supportGroupsURL: "https://www.uc.edu/campus-life/student-affairs/counseling/services/support-groups.html",
            crisisSupportPhone: "988"
        )
    }
    
    func getResources(for university: String) -> MentalHealthResources {
        // Try to find exact match first
        if let resources = universityResources[university] {
            return resources
        }
        
        // Try case-insensitive match
        for (key, value) in universityResources {
            if key.localizedCaseInsensitiveCompare(university) == .orderedSame {
                return value
            }
        }
        
        // Try partial match (in case university name is slightly different)
        let universityLower = university.lowercased()
        for (key, value) in universityResources {
            if key.lowercased().contains(universityLower) || universityLower.contains(key.lowercased()) {
                return value
            }
        }
        
        // Return default resources if no match found
        return MentalHealthResources.defaultResources
    }
}

