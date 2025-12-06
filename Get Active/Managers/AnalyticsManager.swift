import Foundation

class AnalyticsManager: ObservableObject {
    @Published var analytics: [String: EventAnalytics] = [:]
    @Published var viewCounts: [String: Int] = [:] // Track actual view counts
    
    func getAnalytics(for eventId: String, event: Event? = nil) -> EventAnalytics {
        // If we have live event data, use it
        if let event = event {
            let views = viewCounts[eventId] ?? 0
            let likes = event.likedBy.count
            let attendees = event.attending.count
            let shares = 0 // Shares not tracked in Event model yet
            let ratings = event.ratings
            
            let newAnalytics = EventAnalytics(
                eventId: eventId,
                views: views,
                likes: likes,
                attendees: attendees,
                shares: shares,
                aiFeedback: generateAIFeedback(for: event, views: views, likes: likes, attendees: attendees),
                ratings: ratings
            )
            
            analytics[eventId] = newAnalytics
            return newAnalytics
        }
        
        // Fallback to cached analytics
        if let existing = analytics[eventId] {
            return existing
        }
        
        // Generate default analytics if no event data
        let newAnalytics = EventAnalytics(
            eventId: eventId,
            views: 0,
            likes: 0,
            attendees: 0,
            shares: 0,
            aiFeedback: "No data available yet. Start promoting your event to see analytics!",
            ratings: []
        )
        
        analytics[eventId] = newAnalytics
        return newAnalytics
    }
    
    private func generateAIFeedback(for event: Event, views: Int, likes: Int, attendees: Int) -> String {
        let likeRatio = views > 0 ? Double(likes) / Double(views) : 0.0
        let attendanceRatio = likes > 0 ? Double(attendees) / Double(likes) : 0.0
        let daysUntilEvent = Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0
        
        var feedback = ""
        
        // Views feedback
        if views == 0 {
            feedback = feedback + "⚠️ Your event hasn't received any views yet. Try sharing it on social media or with friends to increase visibility. "
        } else if views < 10 {
            feedback = feedback + "📊 Low visibility detected (\(views) views). Consider posting reminders and sharing in campus groups. "
        } else if views < 50 {
            feedback = feedback + "📈 Decent visibility with \(views) views. Keep promoting to reach more students. "
        } else {
            feedback = feedback + "🔥 Strong visibility with \(views) views! Your event is getting noticed. "
        }
        
        // Engagement feedback
        if likeRatio > 0.3 {
            let percentage = Int(likeRatio * 100)
            feedback = feedback + "💚 Excellent engagement rate! \(percentage)% of viewers are interested. "
        } else if likeRatio > 0.15 {
            let percentage = Int(likeRatio * 100)
            feedback = feedback + "👍 Good engagement - \(percentage)% like rate. Keep the momentum going! "
        } else if likeRatio > 0 {
            let percentage = Int(likeRatio * 100)
            feedback = feedback + "📌 Room for improvement - only \(percentage)% engagement. Consider improving your event description or timing. "
        }
        
        // Attendance feedback
        if attendanceRatio > 0.8 {
            feedback = feedback + "🎉 Amazing! Most people who liked are attending (\(attendees) confirmed). "
        } else if attendanceRatio > 0.5 {
            feedback = feedback + "✅ Good conversion - \(attendees) attendees from \(likes) likes. "
        } else if likes > 0 && attendees == 0 {
            feedback = feedback + "⚠️ You have \(likes) likes but no confirmed attendees yet. Consider sending reminders or improving event details. "
        }
        
        // Timing feedback
        if daysUntilEvent < 0 {
            feedback = feedback + "⏰ This event has passed. Review these metrics for future events!"
        } else if daysUntilEvent == 0 {
            feedback = feedback + "🎯 Event is today! Make final announcements to boost attendance. "
        } else if daysUntilEvent <= 3 {
            feedback = feedback + "⏳ Event is in \(daysUntilEvent) day\(daysUntilEvent == 1 ? "" : "s"). Perfect time for final push promotions! "
        } else if daysUntilEvent <= 7 {
            feedback = feedback + "📅 Event is in \(daysUntilEvent) days. Consider daily reminders to maintain interest. "
        } else {
            feedback = feedback + "📆 Event is \(daysUntilEvent) days away. Good time to start building anticipation. "
        }
        
        // Overall recommendation
        if likes >= 20 && attendees >= 10 {
            feedback = feedback + "🌟 Outstanding performance! Your event is trending well."
        } else if likes >= 10 {
            feedback = feedback + "💡 Pro tip: Engage with your audience by responding to questions and posting updates."
        } else {
            feedback = feedback + "💡 Tip: Add compelling images and detailed descriptions to attract more interest."
        }
        
        return feedback.isEmpty ? "Keep promoting your event to see analytics!" : feedback
    }
    
    func updateViews(for eventId: String) {
        viewCounts[eventId] = (viewCounts[eventId] ?? 0) + 1
    }
    
    func getTotalAnalytics(for userId: String, events: [Event]) -> EventAnalytics {
        let userEvents = events.filter { $0.createdBy == userId }
        var totalViews = 0
        var totalLikes = 0
        var totalAttendees = 0
        for event in userEvents {
            totalViews += viewCounts[event.id] ?? 0
            totalLikes += event.likedBy.count
            totalAttendees += event.attending.count
        }
        
        let totalShares = 0 // Shares not tracked in Event model yet
        
        // Collect all ratings from user events
        var allRatings: [EventRating] = []
        for event in userEvents {
            allRatings.append(contentsOf: event.ratings)
        }
        
        return EventAnalytics(
            eventId: "total",
            views: totalViews,
            likes: totalLikes,
            attendees: totalAttendees,
            shares: totalShares,
            aiFeedback: generateTotalFeedback(totalViews: totalViews, totalLikes: totalLikes, totalAttendees: totalAttendees, eventCount: userEvents.count),
            ratings: allRatings
        )
    }
    
    private func generateTotalFeedback(totalViews: Int, totalLikes: Int, totalAttendees: Int, eventCount: Int) -> String {
        guard eventCount > 0 else {
            return "📝 You haven't created any events yet. Post your first event to start seeing analytics!"
        }
        
        var feedback = "📊 Overall Analytics Summary:\n\n"
        feedback = feedback + "• Total Events: \(eventCount)\n"
        feedback = feedback + "• Total Views: \(totalViews)\n"
        feedback = feedback + "• Total Likes: \(totalLikes)\n"
        feedback = feedback + "• Total Attendees: \(totalAttendees)\n\n"
        
        let avgViews = Double(totalViews) / Double(eventCount)
        let avgLikes = Double(totalLikes) / Double(eventCount)
        
        if avgViews > 50 {
            feedback = feedback + "🔥 Great visibility across all events! Your content resonates with students. "
        } else if avgViews > 20 {
            feedback = feedback + "📈 Solid performance. Consider cross-promoting your events for better reach. "
        } else {
            feedback = feedback + "💡 Tips to improve: Post consistently, use eye-catching images, and share in campus groups. "
        }
        
        if avgLikes > 15 {
            feedback = feedback + "High engagement rate shows students love your events! "
        } else if Double(totalAttendees) > Double(totalLikes) * 0.7 {
            feedback = feedback + "Excellent conversion - most interested users are attending! "
        }
        
        return feedback
    }
}

