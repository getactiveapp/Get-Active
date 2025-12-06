import Foundation
import SwiftUI

class EventManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var favoriteEvents: [Event] = []
    
    init() {
        loadSampleEvents()
    }
    
    func loadSampleEvents() {
        let calendar = Calendar.current
        let now = Date()
        
        events = [
            Event(
                title: "HBCU Tech on the Yard",
                description: "Innovative tech showcase featuring HBCU students and alumni. Explore cutting-edge projects, network with tech professionals, and discover opportunities in the tech industry.",
                date: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                startTime: "3:00 PM",
                endTime: "7:00 PM",
                location: "Campus Yard - Tech Pavilion",
                category: .technology,
                tags: ["Technology", "Career"],
                backgroundColor: "blue",
                iconName: "graduationcap.fill",
                createdBy: "HBCU Tech Alliance",
                likedBy: ["friend1", "friend2", "friend3", "friend4"],
                attending: ["friend1", "friend2", "friend3", "friend4"],
                isFeatured: true
            ),
            Event(
                title: "Stop Light Party",
                description: "Come party with us!",
                date: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                startTime: "9:00 PM",
                endTime: "2:00 AM",
                location: "Beacon Lounge",
                category: .party,
                tags: ["Party"],
                backgroundColor: "green",
                createdBy: "admin",
                isFeatured: true
            ),
            Event(
                title: "Campus Music Festival",
                description: "Live music and performances",
                date: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                startTime: "5:00 PM",
                endTime: "10:00 PM",
                location: "Main Quad",
                category: .party,
                tags: ["Music"],
                backgroundColor: "purple",
                createdBy: "admin",
                likedBy: ["friend1"],
                attending: ["friend1"]
            ),
            Event(
                title: "Career Fair",
                description: "Meet employers and explore opportunities",
                date: calendar.date(byAdding: .day, value: 4, to: now) ?? now,
                startTime: "10:00 AM",
                endTime: "4:00 PM",
                location: "Student Center",
                category: .career,
                tags: ["Career"],
                backgroundColor: "orange",
                createdBy: "admin",
                likedBy: ["friend2"]
            ),
            Event(
                title: "CSU Community Service Day",
                description: "Give back to the community",
                date: calendar.date(byAdding: .hour, value: 10, to: now) ?? now,
                startTime: "9:00 AM",
                endTime: "3:00 PM",
                location: "Meet at Student Center",
                category: .other,
                tags: ["Service"],
                backgroundColor: "red",
                createdBy: "admin"
            ),
            Event(
                title: "Marauder Wellness Fair",
                description: "Health and wellness resources",
                date: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                startTime: "11:00 AM",
                endTime: "3:00 PM",
                location: "Recreation Center",
                category: .mentalHealth,
                tags: ["Wellness"],
                backgroundColor: "teal",
                createdBy: "admin"
            ),
            Event(
                title: "CSU Greek Life Showcase",
                description: "Learn about Greek organizations",
                date: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                startTime: "6:00 PM",
                endTime: "9:00 PM",
                location: "Campus Yard",
                category: .club,
                tags: ["Greek Life"],
                backgroundColor: "red",
                createdBy: "admin"
            ),
            Event(
                title: "Soccer Match",
                description: "Intramural soccer game",
                date: now,
                startTime: "4:00 PM",
                endTime: "6:00 PM",
                location: "Sports Field",
                category: .other,
                tags: ["Sports"],
                backgroundColor: "green",
                iconName: "soccerball",
                createdBy: "admin",
                isFeatured: false
            ),
            // More events happening today
            Event(
                title: "Morning Yoga Session",
                description: "Start your day with a relaxing yoga session. All levels welcome. Mats provided.",
                date: now,
                startTime: "8:00 AM",
                endTime: "9:00 AM",
                location: "Recreation Center - Yoga Studio",
                category: .mentalHealth,
                tags: ["Wellness", "Yoga", "Fitness"],
                backgroundColor: "teal",
                iconName: "figure.yoga",
                createdBy: "Wellness Center",
                likedBy: ["friend1"],
                isFeatured: false
            ),
            Event(
                title: "Coffee & Study",
                description: "Join fellow students for a study session with free coffee and snacks. Quiet study environment.",
                date: now,
                startTime: "10:00 AM",
                endTime: "12:00 PM",
                location: "Library - Study Commons",
                category: .academic,
                tags: ["Study", "Academic", "Coffee"],
                backgroundColor: "brown",
                iconName: "book.fill",
                createdBy: "Library Services",
                likedBy: ["friend2", "friend3"],
                attending: ["friend2"],
                isFeatured: false
            ),
            Event(
                title: "Lunch with Faculty",
                description: "Informal lunch meeting with professors. Great opportunity to network and ask questions.",
                date: now,
                startTime: "12:00 PM",
                endTime: "1:30 PM",
                location: "Cafeteria - Faculty Dining",
                category: .academic,
                tags: ["Networking", "Academic", "Lunch"],
                backgroundColor: "orange",
                iconName: "person.2.fill",
                createdBy: "Student Affairs",
                isFeatured: false
            ),
            Event(
                title: "Art Club Exhibition",
                description: "View student artwork and meet the artists. Refreshments provided.",
                date: now,
                startTime: "2:00 PM",
                endTime: "5:00 PM",
                location: "Art Gallery",
                category: .club,
                tags: ["Art", "Exhibition", "Club"],
                backgroundColor: "purple",
                iconName: "paintpalette.fill",
                createdBy: "Art Club",
                likedBy: ["friend4"],
                isFeatured: false
            ),
            Event(
                title: "Study Group: Math 101",
                description: "Collaborative study session for Math 101. Bring your homework and questions!",
                date: now,
                startTime: "3:00 PM",
                endTime: "5:00 PM",
                location: "Math Building - Room 201",
                category: .academic,
                tags: ["Study", "Math", "Academic"],
                backgroundColor: "blue",
                iconName: "function",
                createdBy: "Math Department",
                likedBy: ["friend1", "friend3"],
                attending: ["friend1"],
                isFeatured: false
            ),
            Event(
                title: "Soccer Match",
                description: "Intramural soccer game",
                date: now,
                startTime: "4:00 PM",
                endTime: "6:00 PM",
                location: "Sports Field",
                category: .other,
                tags: ["Sports"],
                backgroundColor: "green",
                iconName: "soccerball",
                createdBy: "admin",
                isFeatured: false
            ),
            Event(
                title: "Evening Prayer Service",
                description: "Join us for evening prayer and reflection. All are welcome.",
                date: now,
                startTime: "6:00 PM",
                endTime: "6:30 PM",
                location: "Chapel",
                category: .prayer,
                tags: ["Prayer", "Spiritual"],
                backgroundColor: "indigo",
                iconName: "hands.sparkles.fill",
                createdBy: "Campus Ministry",
                isFeatured: false
            ),
            Event(
                title: "Game Night",
                description: "Board games, card games, and video games. Pizza and drinks provided!",
                date: now,
                startTime: "7:00 PM",
                endTime: "10:00 PM",
                location: "Student Center - Game Room",
                category: .other,
                tags: ["Games", "Social", "Entertainment"],
                backgroundColor: "purple",
                iconName: "gamecontroller.fill",
                createdBy: "Student Activities",
                likedBy: ["friend2", "friend3", "friend4"],
                attending: ["friend2", "friend3"],
                isFeatured: false
            ),
            Event(
                title: "Open Mic Night",
                description: "Showcase your talent! Sign up to perform or just come to enjoy the show.",
                date: now,
                startTime: "8:00 PM",
                endTime: "10:00 PM",
                location: "Student Center - Stage",
                category: .party,
                tags: ["Music", "Performance", "Entertainment"],
                backgroundColor: "pink",
                iconName: "mic.fill",
                createdBy: "Music Club",
                likedBy: ["friend1", "friend4"],
                isFeatured: false
            )
        ]
        
        // Add events for December 11th and 12th
        let december11 = createDate(year: 2024, month: 12, day: 11)
        let december12 = createDate(year: 2024, month: 12, day: 12)
        
        let decemberEvents = [
            // December 11th Events
            Event(
                title: "Final Exam Study Session",
                description: "Join us for a collaborative study session before finals. Bring your notes and study materials. Snacks and coffee provided!",
                date: december11,
                startTime: "6:00 PM",
                endTime: "9:00 PM",
                location: "Library - Study Room A",
                category: .academic,
                tags: ["Study", "Finals", "Academic"],
                backgroundColor: "purple",
                iconName: "book.fill",
                createdBy: "Student Government",
                likedBy: ["friend1", "friend2"],
                attending: ["friend1"],
                isFeatured: true
            ),
            Event(
                title: "Holiday Market",
                description: "Local vendors selling handmade gifts, crafts, and holiday treats. Perfect for finding unique gifts for the holidays!",
                date: december11,
                startTime: "10:00 AM",
                endTime: "4:00 PM",
                location: "Student Center - Main Hall",
                category: .vendor,
                tags: ["Holiday", "Shopping", "Vendors"],
                backgroundColor: "orange",
                iconName: "cart.fill",
                createdBy: "Campus Activities",
                likedBy: ["friend3"],
                isFeatured: false
            ),
            Event(
                title: "Basketball Game: CSU vs Rivals",
                description: "Cheer on the Marauders as they take on their biggest rivals! Free admission for students. Wear your school colors!",
                date: december11,
                startTime: "7:00 PM",
                endTime: "9:30 PM",
                location: "Gymnasium",
                category: .other,
                tags: ["Sports", "Basketball", "School Spirit"],
                backgroundColor: "red",
                iconName: "basketball.fill",
                createdBy: "Athletics Department",
                likedBy: ["friend1", "friend2", "friend3", "friend4"],
                attending: ["friend1", "friend2", "friend3"],
                isFeatured: true
            ),
            Event(
                title: "Stress Relief Workshop",
                description: "Learn techniques to manage stress during finals week. Meditation, breathing exercises, and wellness tips.",
                date: december11,
                startTime: "2:00 PM",
                endTime: "3:30 PM",
                location: "Wellness Center",
                category: .mentalHealth,
                tags: ["Wellness", "Mental Health", "Stress Relief"],
                backgroundColor: "teal",
                iconName: "heart.fill",
                createdBy: "Counseling Services",
                isFeatured: false
            ),
            Event(
                title: "Gospel Choir Performance",
                description: "Annual holiday performance by the CSU Gospel Choir. Featuring traditional and contemporary gospel music.",
                date: december11,
                startTime: "6:30 PM",
                endTime: "8:00 PM",
                location: "Auditorium",
                category: .other,
                tags: ["Music", "Performance", "Holiday"],
                backgroundColor: "blue",
                iconName: "music.note",
                createdBy: "Gospel Choir",
                likedBy: ["friend2"],
                isFeatured: false
            ),
            
            // December 12th Events
            Event(
                title: "Winter Formal",
                description: "Dress to impress at the annual Winter Formal! Music, dancing, and refreshments. Semi-formal attire required.",
                date: december12,
                startTime: "8:00 PM",
                endTime: "12:00 AM",
                location: "Student Center - Ballroom",
                category: .party,
                tags: ["Dance", "Formal", "Social"],
                backgroundColor: "purple",
                iconName: "music.note",
                createdBy: "Student Activities Board",
                likedBy: ["friend1", "friend2", "friend3", "friend4"],
                attending: ["friend1", "friend2", "friend3", "friend4"],
                isFeatured: true
            ),
            Event(
                title: "Graduation Rehearsal",
                description: "Mandatory rehearsal for December graduates. Learn about ceremony procedures and receive your cap and gown.",
                date: december12,
                startTime: "10:00 AM",
                endTime: "12:00 PM",
                location: "Main Auditorium",
                category: .academic,
                tags: ["Graduation", "Academic"],
                backgroundColor: "blue",
                iconName: "graduationcap.fill",
                createdBy: "Registrar's Office",
                isFeatured: false
            ),
            Event(
                title: "Holiday Cookie Decorating",
                description: "Unwind before finals with cookie decorating! All supplies provided. Bring your creativity!",
                date: december12,
                startTime: "3:00 PM",
                endTime: "5:00 PM",
                location: "Student Center - Activity Room",
                category: .other,
                tags: ["Holiday", "Crafts", "Social"],
                backgroundColor: "orange",
                iconName: "paintbrush.fill",
                createdBy: "Residence Life",
                likedBy: ["friend3", "friend4"],
                attending: ["friend3"],
                isFeatured: false
            ),
            Event(
                title: "Career Networking Mixer",
                description: "Network with alumni and professionals in your field. Light refreshments and professional development tips.",
                date: december12,
                startTime: "5:00 PM",
                endTime: "7:00 PM",
                location: "Alumni Center",
                category: .career,
                tags: ["Networking", "Career", "Professional"],
                backgroundColor: "orange",
                iconName: "briefcase.fill",
                createdBy: "Career Services",
                likedBy: ["friend2", "friend4"],
                isFeatured: false
            ),
            Event(
                title: "Prayer Circle",
                description: "Join us for a time of prayer and reflection before finals week. All faiths welcome.",
                date: december12,
                startTime: "12:00 PM",
                endTime: "12:30 PM",
                location: "Chapel",
                category: .prayer,
                tags: ["Prayer", "Spiritual", "Community"],
                backgroundColor: "indigo",
                iconName: "hands.sparkles.fill",
                createdBy: "Campus Ministry",
                likedBy: ["friend1"],
                isFeatured: false
            ),
            Event(
                title: "Study Break: Movie Night",
                description: "Take a break from studying! Join us for a holiday movie screening. Popcorn and drinks provided.",
                date: december12,
                startTime: "7:00 PM",
                endTime: "9:30 PM",
                location: "Student Center - Theater",
                category: .other,
                tags: ["Movie", "Study Break", "Entertainment"],
                backgroundColor: "purple",
                iconName: "tv.fill",
                createdBy: "Student Activities",
                likedBy: ["friend1", "friend3"],
                attending: ["friend1"],
                isFeatured: false
            ),
            Event(
                title: "Computer Science Club Meeting",
                description: "Final meeting of the semester! Discuss upcoming projects and celebrate the end of the semester.",
                date: december12,
                startTime: "4:00 PM",
                endTime: "5:30 PM",
                location: "Computer Lab - Room 205",
                category: .club,
                tags: ["Technology", "Club", "Academic"],
                backgroundColor: "blue",
                iconName: "laptopcomputer",
                createdBy: "CS Club President",
                likedBy: ["friend2"],
                isFeatured: false
            )
        ]
        
        events.append(contentsOf: decemberEvents)
    }
    
    private func createDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    func toggleFavorite(eventId: String, userId: String) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            let wasLiked = events[index].likedBy.contains(userId)
            
            if wasLiked {
                // Unliking - only cancel notifications if user is not going
                events[index].likedBy.removeAll { $0 == userId }
                // Only cancel notifications if user is not going (notifications come from "I'm Going", not liking)
                if !events[index].attending.contains(userId) {
                    NotificationManager.shared.cancelNotifications(for: eventId, userId: userId)
                }
            } else {
                // Liking - don't schedule notifications here (only when user clicks "I'm Going")
                if !events[index].likedBy.contains(userId) {
                    events[index].likedBy.append(userId)
                }
                // Notifications are now only scheduled when user clicks "I'm Going" after RSVP
            }
            updateFavoriteEvents(userId: userId)
        }
    }
    
    func updateFavoriteEvents(userId: String) {
        // Include events that are liked OR RSVP'd
        favoriteEvents = events.filter { event in
            event.likedBy.contains(userId) || event.rsvpBy.contains(userId)
        }
        // Sort by date (upcoming events first)
        favoriteEvents.sort { $0.date < $1.date }
    }
    
    func refreshFavoriteEvents(userId: String) {
        updateFavoriteEvents(userId: userId)
    }
    
    func getEventsForToday() -> [Event] {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return events.filter { event in
            // Normalize event date to start of day for comparison
            let eventDate = calendar.startOfDay(for: event.date)
            // Check if event date is exactly today (between today and tomorrow)
            return eventDate >= today && eventDate < tomorrow
        }
    }
    
    func getFeaturedEvents() -> [Event] {
        return events.filter { $0.isFeatured }
    }
    
    func getAllEventsSorted() -> [Event] {
        // Sort events by date (upcoming first), then by creation order (newest first for same date)
        // Events are sorted with future events first, then today's events, then past events
        return events.sorted { event1, event2 in
            let calendar = Calendar.current
            
            let event1Date = calendar.startOfDay(for: event1.date)
            let event2Date = calendar.startOfDay(for: event2.date)
            
            // If both events are on different days, sort by date (earliest first)
            if event1Date != event2Date {
                return event1.date < event2.date
            }
            
            // If same date, keep original order (newer events added later will appear later in the list)
            // Since we're appending new events, they'll appear at the end, which is what we want for same-day events
            return false
        }
    }
    
    func getEventsForUniversity(_ university: University) -> [Event] {
        // Filter events that might be at this university
        // Check if location contains university name or common campus locations
        let universityNameLower = university.name.lowercased()
        let universityAbbreviation = university.abbreviation.lowercased()
        
        return events.filter { event in
            let locationLower = event.location.lowercased()
            // Check if location contains university name, abbreviation, or common campus terms
            return locationLower.contains(universityNameLower) ||
                   locationLower.contains(universityAbbreviation) ||
                   locationLower.contains("campus") ||
                   locationLower.contains("student center") ||
                   locationLower.contains("quad") ||
                   locationLower.contains("library") ||
                   locationLower.contains("gym") ||
                   locationLower.contains("field") ||
                   locationLower.contains("hall")
        }
    }
    
    func initializeFavoritesForUser(userId: String) {
        // Initialize some events as favorites for the demo user
        // Add user to likedBy for some events and to attending for others
        let favoriteEventTitles = [
            "HBCU Tech on the Yard",
            "Stop Light Party",
            "Campus Music Festival",
            "Career Fair",
            "Basketball Game: CSU vs Rivals",
            "Winter Formal"
        ]
        
        let attendingEventTitles = [
            "HBCU Tech on the Yard",
            "Basketball Game: CSU vs Rivals",
            "Winter Formal"
        ]
        
        for (index, event) in events.enumerated() {
            if favoriteEventTitles.contains(event.title) {
                if !events[index].likedBy.contains(userId) {
                    events[index].likedBy.append(userId)
                }
            }
            
            if attendingEventTitles.contains(event.title) {
                if !events[index].attending.contains(userId) {
                    events[index].attending.append(userId)
                }
            }
        }
        
        // Update favorite events list
        updateFavoriteEvents(userId: userId)
        
        // Schedule notifications for all liked events
        Task {
            let hasPermission = await NotificationManager.shared.requestAuthorization()
            if hasPermission {
                await MainActor.run {
                    NotificationManager.shared.scheduleNotificationsForAllLikedEvents(events: events, userId: userId)
                }
            }
        }
    }
}

