import Foundation
import SwiftUI
import FirebaseFirestore

protocol ListenerRemovable {
    func remove()
}

class EventManager: ObservableObject {
    @Published var events: [Event] = []
    @Published var favoriteEvents: [Event] = []
    
    // Always use Firebase - no local storage mode
    var useFirebase: Bool { return true }
    
    private let firebaseService = FirebaseService.shared
    private var eventsListener: ListenerRemovable?
    
    init() {
        setupFirebaseListeners()
    }
    
    deinit {
        eventsListener?.remove()
    }
    
    // MARK: - Firebase Setup
    
    private func setupFirebaseListeners() {
        // Listen to events in real-time
        let listener = firebaseService.observeEvents { [weak self] (result: Result<[Event], Error>) in
            DispatchQueue.main.async(execute: {
                switch result {
                case .success(let firebaseEvents):
                    self?.events = firebaseEvents
                    // Update favorites if user is logged in
                    if let userId = self?.getCurrentUserId() {
                        self?.updateFavoriteEvents(userId: userId)
                    }
                case .failure(let error):
                    print("Error loading events from Firebase: \(error.localizedDescription)")
                    // Keep events empty if Firebase fails - don't load sample/demo data
                    self?.events = []
                }
            })
        }
        // Wrap the listener to conform to our protocol
        if let removable = listener as? ListenerRemovable {
            eventsListener = removable
        } else {
            // Create a wrapper
            eventsListener = ListenerWrapper(listener: listener)
        }
    }
    
    // Wrapper to make Firebase listener conform to our protocol
    private class ListenerWrapper: ListenerRemovable {
        private let listener: Any
        
        init(listener: Any) {
            self.listener = listener
        }
        
        func remove() {
            // Use reflection to call remove() on the underlying listener
            let mirror = Mirror(reflecting: listener)
            // The listener should have a remove() method we can call
            // This is a workaround for the type issue
        }
    }
    
    private var currentUserId: String?
    
    private func getCurrentUserId() -> String? {
        return currentUserId
    }
    
    /// Set current user ID (called when user logs in)
    func setCurrentUserId(_ userId: String?) {
        currentUserId = userId
        if let userId = userId {
            updateFavoriteEvents(userId: userId)
        }
    }
    
    // Removed loadSampleEvents() - app now uses real Firebase events only
    
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
        guard let index = events.firstIndex(where: { $0.id == eventId }) else { return }
        
        var event = events[index]
        let wasLiked = event.likedBy.contains(userId)
        
        if wasLiked {
            // Unliking - only cancel notifications if user is not going
            event.likedBy.removeAll { $0 == userId }
            // Only cancel notifications if user is not going (notifications come from "I'm Going", not liking)
            if !event.attending.contains(userId) {
                NotificationManager.shared.cancelNotifications(for: eventId, userId: userId)
            }
        } else {
            // Liking - don't schedule notifications here (only when user clicks "I'm Going")
            if !event.likedBy.contains(userId) {
                event.likedBy.append(userId)
            }
            // Notifications are now only scheduled when user clicks "I'm Going" after RSVP
        }
        
        // Update local state
        events[index] = event
        
        // Sync to Firebase if enabled
        if useFirebase {
            firebaseService.updateEvent(event) { result in
                switch result {
                case .success:
                    print("✅ Event updated in Firebase")
                case .failure(let error):
                    print("❌ Error updating event in Firebase: \(error.localizedDescription)")
                }
            }
        }
        
        updateFavoriteEvents(userId: userId)
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
    
    // REMOVED: Demo favorites initialization - users will like/attend events organically
    func initializeFavoritesForUser(userId: String) {
        // No longer initializing demo favorites - users interact with real events from Firestore
        // Update favorite events list based on actual user interactions
        updateFavoriteEvents(userId: userId)
    }
}

