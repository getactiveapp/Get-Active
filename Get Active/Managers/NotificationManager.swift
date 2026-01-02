import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                checkAuthorizationStatus()
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    func scheduleNotification(for event: Event, userId: String, advanceMinutes: Int = 30) {
        // Check if user is going to this event (notifications are scheduled when user clicks "I'm Going")
        guard event.attending.contains(userId) else {
            return
        }
        
        // Parse event start and end times
        let eventStartDate = combineDateAndTime(event.date, timeString: event.startTime)
        let eventEndDate = combineDateAndTime(event.date, timeString: event.endTime)
        let now = Date()
        
        // Only schedule if event is in the future
        guard eventStartDate > now else {
            return
        }
        
        // Validate advance minutes is one of the allowed options
        let allowedValues = [15, 30, 50]
        let validAdvanceMinutes = allowedValues.contains(advanceMinutes) ? advanceMinutes : 30
        
        // Schedule notification X minutes before event (based on user preference)
        scheduleAdvanceNotification(for: event, startDate: eventStartDate, advanceMinutes: validAdvanceMinutes, userId: userId)
        
        // Schedule notification when event starts
        scheduleEventStartNotification(for: event, startDate: eventStartDate, userId: userId)
        
        // Schedule notification for survey at end of event
        scheduleEndOfEventSurveyNotification(for: event, endDate: eventEndDate, userId: userId)
    }
    
    private func scheduleAdvanceNotification(for event: Event, startDate: Date, advanceMinutes: Int, userId: String) {
        let calendar = Calendar.current
        guard let advanceTime = calendar.date(byAdding: .minute, value: -advanceMinutes, to: startDate) else {
            return
        }
        
        // Only schedule if the notification time is in the future
        guard advanceTime > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "\(event.title) Starting Soon!"
        
        // Format the advance time message
        let timeMessage: String
        if advanceMinutes == 15 {
            timeMessage = "Starts in 15 minutes"
        } else if advanceMinutes == 30 {
            timeMessage = "Starts in 30 minutes"
        } else {
            timeMessage = "Starts in 50 minutes"
        }
        
        content.body = "\(timeMessage) at \(event.startTime) - \(event.location)"
        content.sound = .default
        content.userInfo = [
            "eventId": event.id,
            "type": "advanceNotification",
            "advanceMinutes": advanceMinutes
        ]
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: advanceTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "\(event.id)_advance_\(userId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling advance notification: \(error)")
            } else {
                print("Scheduled notification \(advanceMinutes) minutes before: \(event.title)")
            }
        }
    }
    
    private func scheduleEventStartNotification(for event: Event, startDate: Date, userId: String) {
        let calendar = Calendar.current
        let now = Date()
        
        // Only schedule if the event start time is in the future
        guard startDate > now else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "\(event.title) Starting Now!"
        content.body = "The event is starting now at \(event.location). Don't forget to click 'I'm Here!'"
        content.sound = .default
        content.userInfo = [
            "eventId": event.id,
            "type": "eventStart"
        ]
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: startDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "\(event.id)_eventStart_\(userId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling event start notification: \(error)")
            } else {
                print("Scheduled notification for event start: \(event.title)")
            }
        }
    }
    
    private func scheduleEndOfEventSurveyNotification(for event: Event, endDate: Date, userId: String) {
        let calendar = Calendar.current
        let now = Date()
        
        // Only schedule if the event end time is in the future
        guard endDate > now else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "How was \(event.title)?"
        content.body = "Share your feedback about the event!"
        content.sound = .default
        content.userInfo = [
            "eventId": event.id,
            "type": "endOfEventSurvey"
        ]
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: endDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "\(event.id)_survey_\(userId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling end of event survey notification: \(error)")
            } else {
                print("Scheduled survey notification for end of event: \(event.title)")
            }
        }
    }
    
    func cancelNotifications(for eventId: String, userId: String) {
        let identifiers = [
            "\(eventId)_advance_\(userId)",
            "\(eventId)_eventStart_\(userId)",
            "\(eventId)_survey_\(userId)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled notifications for event: \(eventId)")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func scheduleNotificationsForAllLikedEvents(events: [Event], userId: String, advanceMinutes: Int = 30) {
        // Cancel all existing notifications first to avoid duplicates
        cancelAllNotifications()
        
        // Validate advance minutes
        let allowedValues = [15, 30, 50]
        let validAdvanceMinutes = allowedValues.contains(advanceMinutes) ? advanceMinutes : 30
        
        // Schedule notifications for all events user is going to (not just liked)
        // Notifications are only sent when user clicks "I'm Going" after RSVP
        for event in events {
            if event.attending.contains(userId) {
                scheduleNotification(for: event, userId: userId, advanceMinutes: validAdvanceMinutes)
            }
        }
    }
    
    // MARK: - Friend Notifications
    
    /// Send an immediate notification when someone sends you a friend request
    func sendFriendRequestNotification(fromUserName: String, toUserId: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Friend Request!"
        content.body = "\(fromUserName) sent you a friend request"
        content.sound = .default
        content.userInfo = [
            "type": "friendRequest",
            "fromUserName": fromUserName
        ]
        
        // Send immediately (no trigger means it fires immediately)
        let identifier = "friendRequest_\(fromUserName)_\(toUserId)_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending friend request notification: \(error)")
            } else {
                print("Sent friend request notification from \(fromUserName)")
            }
        }
    }
    
    /// Send an immediate notification when someone accepts your friend request
    func sendFriendAcceptNotification(fromUserName: String, toUserId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Friend Request Accepted!"
        content.body = "\(fromUserName) accepted your friend request"
        content.sound = .default
        content.userInfo = [
            "type": "friendAccept",
            "fromUserName": fromUserName
        ]
        
        // Send immediately (no trigger means it fires immediately)
        let identifier = "friendAccept_\(fromUserName)_\(toUserId)_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending friend accept notification: \(error)")
            } else {
                print("Sent friend accept notification from \(fromUserName)")
            }
        }
    }
    
    // MARK: - Message Notifications
    
    /// Send an immediate notification when a friend sends you a message
    func sendMessageNotification(fromUserName: String, messageText: String, toUserId: String, fromUserId: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(fromUserName)"
        content.body = messageText
        content.sound = .default
        content.userInfo = [
            "type": "message",
            "fromUserName": fromUserName,
            "fromUserId": fromUserId,
            "messageText": messageText
        ]
        
        // Send immediately (no trigger means it fires immediately)
        let identifier = "message_\(fromUserId)_\(toUserId)_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending message notification: \(error)")
            } else {
                print("Sent message notification from \(fromUserName)")
            }
        }
    }
    
    private func combineDateAndTime(_ date: Date, timeString: String) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Parse time string (e.g., "3:00 PM" or "15:00")
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
        let lowercase = trimmed.lowercased()
        
        // Handle "TBD" or empty strings
        if lowercase == "tbd" || trimmed.isEmpty {
            return (0, 0)
        }
        
        // Try to parse format like "3:00 PM" or "15:00"
        if lowercase.contains("am") || lowercase.contains("pm") {
            // 12-hour format
            let timePart = lowercase.replacingOccurrences(of: "am", with: "").replacingOccurrences(of: "pm", with: "").trimmingCharacters(in: .whitespaces)
            let components = timePart.components(separatedBy: ":")
            
            if components.count >= 2,
               let hour = Int(components[0]),
               let minute = Int(components[1]) {
                var finalHour = hour
                
                if lowercase.contains("pm") && hour != 12 {
                    finalHour = hour + 12
                } else if lowercase.contains("am") && hour == 12 {
                    finalHour = 0
                }
                
                return (finalHour, minute)
            }
        } else {
            // 24-hour format
            let components = trimmed.components(separatedBy: ":")
            if components.count >= 2,
               let hour = Int(components[0]),
               let minute = Int(components[1]) {
                return (hour, minute)
            }
        }
        
        return (0, 0)
    }
}

