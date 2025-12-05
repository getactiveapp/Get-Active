import Foundation
import EventKit
import SwiftUI

class CalendarManager: ObservableObject {
    private let eventStore = EKEventStore()
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var isCalendarLinked: Bool = false
    
    init() {
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        isCalendarLinked = authorizationStatus == .authorized
    }
    
    func requestCalendarAccess() async -> Bool {
        // Use completion handler version for compatibility
        return await withCheckedContinuation { continuation in
            eventStore.requestAccess(to: .event) { granted, error in
                if let error = error {
                    print("Error requesting calendar access: \(error)")
                }
                Task { @MainActor in
                    self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    self.isCalendarLinked = granted
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    func addEventToCalendar(_ event: Event) async -> Bool {
        // Check if we have access
        guard authorizationStatus == .authorized else {
            return false
        }
        
        let ekEvent = EKEvent(eventStore: eventStore)
        ekEvent.title = event.title
        ekEvent.notes = event.description
        ekEvent.startDate = combineDateAndTime(event.date, timeString: event.startTime)
        ekEvent.endDate = combineDateAndTime(event.date, timeString: event.endTime)
        ekEvent.location = event.location
        
        // Handle potential nil calendar
        if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
            ekEvent.calendar = defaultCalendar
        } else {
            // Fallback to first available calendar
            if let firstCalendar = eventStore.calendars(for: .event).first {
                ekEvent.calendar = firstCalendar
            } else {
                print("Error: No calendar available")
                return false
            }
        }
        
        do {
            try eventStore.save(ekEvent, span: .thisEvent)
            return true
        } catch {
            print("Error saving event to calendar: \(error)")
            return false
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
}

