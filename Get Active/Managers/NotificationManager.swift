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
    
    func scheduleNotification(for event: Event, userId: String) {
        // Check if user is going to this event (notifications are scheduled when user clicks "I'm Going")
        guard event.attending.contains(userId) else {
            return
        }
        
        // Parse event start time
        let eventStartDate = combineDateAndTime(event.date, timeString: event.startTime)
        let now = Date()
        
        // Only schedule if event is in the future
        guard eventStartDate > now else {
            return
        }
        
        // Schedule notification 1 hour before event
        scheduleOneHourBeforeNotification(for: event, startDate: eventStartDate, userId: userId)
        
        // Schedule notification when event starts
        scheduleEventStartNotification(for: event, startDate: eventStartDate, userId: userId)
    }
    
    private func scheduleOneHourBeforeNotification(for event: Event, startDate: Date, userId: String) {
        let calendar = Calendar.current
        guard let oneHourBefore = calendar.date(byAdding: .hour, value: -1, to: startDate) else {
            return
        }
        
        // Only schedule if the notification time is in the future
        guard oneHourBefore > Date() else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "\(event.title) Starting Soon!"
        content.body = "Starts in 1 hour at \(event.startTime) - \(event.location)"
        content.sound = .default
        content.userInfo = [
            "eventId": event.id,
            "type": "oneHourBefore"
        ]
        
        let triggerDate = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: oneHourBefore)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let identifier = "\(event.id)_oneHourBefore_\(userId)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling one hour before notification: \(error)")
            } else {
                print("Scheduled notification 1 hour before: \(event.title)")
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
    
    func cancelNotifications(for eventId: String, userId: String) {
        let identifiers = [
            "\(eventId)_oneHourBefore_\(userId)",
            "\(eventId)_eventStart_\(userId)"
        ]
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        print("Cancelled notifications for event: \(eventId)")
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func scheduleNotificationsForAllLikedEvents(events: [Event], userId: String) {
        // Cancel all existing notifications first to avoid duplicates
        cancelAllNotifications()
        
        // Schedule notifications for all events user is going to (not just liked)
        // Notifications are only sent when user clicks "I'm Going" after RSVP
        for event in events {
            if event.attending.contains(userId) {
                scheduleNotification(for: event, userId: userId)
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

