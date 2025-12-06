import Foundation
import UserNotifications

class EventRatingManager: ObservableObject {
    static let shared = EventRatingManager()
    
    private let ratedEventsKey = "RatedEvents_UserDefaults"
    private var ratedEventIds: Set<String> = []
    
    private init() {
        loadRatedEvents()
    }
    
    private func loadRatedEvents() {
        if let data = UserDefaults.standard.data(forKey: ratedEventsKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            ratedEventIds = Set(decoded)
        }
    }
    
    private func saveRatedEvents() {
        if let encoded = try? JSONEncoder().encode(Array(ratedEventIds)) {
            UserDefaults.standard.set(encoded, forKey: ratedEventsKey)
        }
    }
    
    func hasRatedEvent(eventId: String, userId: String) -> Bool {
        return ratedEventIds.contains("\(eventId)_\(userId)")
    }
    
    func markEventAsRated(eventId: String, userId: String) {
        ratedEventIds.insert("\(eventId)_\(userId)")
        saveRatedEvents()
    }
    
    func checkForEndedEventsToRate(events: [Event], userId: String, eventManager: EventManager) {
        let now = Date()
        let calendar = Calendar.current
        
        for event in events {
            // Check if event has ended
            let eventEndDate = combineDateAndTime(event.date, timeString: event.endTime)
            
            // Event ended in the last 24 hours and user attended/RSVP'd
            if eventEndDate < now,
               now.timeIntervalSince(eventEndDate) < 24 * 60 * 60, // Within 24 hours
               (event.attending.contains(userId) || event.rsvpBy.contains(userId)),
               !hasRatedEvent(eventId: event.id, userId: userId),
               !event.ratings.contains(where: { $0.userId == userId }) {
                
                // Schedule notification to rate the event
                scheduleRatingNotification(for: event, userId: userId)
            }
        }
    }
    
    private func combineDateAndTime(_ date: Date, timeString: String) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Parse time string (e.g., "3:00 PM")
        let timeComponents = parseTimeString(timeString)
        
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components) ?? date
    }
    
    private func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int) {
        let trimmed = timeString.trimmingCharacters(in: .whitespaces)
        let isPM = trimmed.uppercased().contains("PM")
        
        let timePart = trimmed.replacingOccurrences(of: "AM", with: "")
            .replacingOccurrences(of: "PM", with: "")
            .replacingOccurrences(of: "am", with: "")
            .replacingOccurrences(of: "pm", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        let components = timePart.split(separator: ":")
        guard components.count >= 1 else { return (12, 0) }
        
        var hour = Int(components[0]) ?? 12
        let minute = components.count > 1 ? Int(components[1]) ?? 0 : 0
        
        if isPM && hour != 12 {
            hour += 12
        } else if !isPM && hour == 12 {
            hour = 0
        }
        
        return (hour, minute)
    }
    
    func scheduleRatingNotification(for event: Event, userId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Rate Your Experience"
        content.body = "How was '\(event.title)'? Share your feedback!"
        content.sound = .default
        content.userInfo = [
            "eventId": event.id,
            "type": "rateEvent",
            "userId": userId
        ]
        
        // Schedule notification 1 hour after event ends
        let eventEndDate = combineDateAndTime(event.date, timeString: event.endTime)
        let calendar = Calendar.current
        guard let notificationTime = calendar.date(byAdding: .hour, value: 1, to: eventEndDate),
              notificationTime > Date() else {
            return
        }
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notificationTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "rateEvent_\(event.id)_\(userId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling rating notification: \(error)")
            } else {
                print("Scheduled rating notification for: \(event.title)")
            }
        }
    }
}

