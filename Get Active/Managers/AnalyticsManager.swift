import Foundation

class AnalyticsManager: ObservableObject {
    @Published var analytics: [String: EventAnalytics] = [:]
    
    func getAnalytics(for eventId: String) -> EventAnalytics {
        if let existing = analytics[eventId] {
            return existing
        }
        
        // Generate sample analytics
        let newAnalytics = EventAnalytics(
            eventId: eventId,
            views: Int.random(in: 50...500),
            likes: Int.random(in: 10...100),
            attendees: Int.random(in: 5...80),
            shares: Int.random(in: 0...50),
            aiFeedback: generateAIFeedback(eventId: eventId)
        )
        
        analytics[eventId] = newAnalytics
        return newAnalytics
    }
    
    private func generateAIFeedback(eventId: String) -> String {
        // In production, this would use a real AI API
        let feedbacks = [
            "Your event is performing well! Engagement is high with good attendance rates. Consider promoting on social media to reach more students.",
            "Great event concept! The attendance numbers are solid. To improve, try posting reminders 24 hours before the event and consider adding more interactive elements.",
            "The event has good visibility. To boost attendance, consider partnering with student organizations and posting in multiple channels.",
            "Strong engagement metrics! Your event is resonating with students. Maintain this momentum by consistently posting quality events.",
            "Good foundation! To maximize reach, consider scheduling events during peak student activity hours (5-8 PM) and cross-promoting with related events."
        ]
        return feedbacks.randomElement() ?? feedbacks[0]
    }
    
    func updateViews(for eventId: String) {
        if var existing = analytics[eventId] {
            existing.views += 1
            analytics[eventId] = existing
        } else {
            let newAnalytics = getAnalytics(for: eventId)
            analytics[eventId] = newAnalytics
        }
    }
}

