import SwiftUI

struct AnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var analyticsManager = AnalyticsManager()
    @ObservedObject var eventManager: EventManager
    let eventId: String
    @State private var selectedEventId: String?
    @State private var showingChart: ChartDetailData? = nil
    
    var userEvents: [Event] {
        guard let userId = authManager.currentUser?.id else { return [] }
        return eventManager.events.filter { $0.createdBy == userId }
    }
    
    var totalAnalytics: EventAnalytics {
        guard let userId = authManager.currentUser?.id else {
            return EventAnalytics(eventId: "total", views: 0, likes: 0, attendees: 0, shares: 0, aiFeedback: "")
        }
        return analyticsManager.getTotalAnalytics(for: userId, events: eventManager.events)
    }
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Event Analytics")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Overall Stats Grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Overall Analytics")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 12) {
                                ClickableStatBox(
                                    title: "Total Views",
                                    value: "\(totalAnalytics.views)",
                                    icon: "eye.fill",
                                    chartType: .views,
                                    analytics: totalAnalytics,
                                    events: userEvents,
                                    analyticsManager: analyticsManager,
                                    onTap: { data in
                                        showingChart = data
                                    }
                                )
                                
                                ClickableStatBox(
                                    title: "Total Likes",
                                    value: "\(totalAnalytics.likes)",
                                    icon: "heart.fill",
                                    chartType: .likes,
                                    analytics: totalAnalytics,
                                    events: userEvents,
                                    analyticsManager: analyticsManager,
                                    onTap: { data in
                                        showingChart = data
                                    }
                                )
                                
                                ClickableStatBox(
                                    title: "Total Attendees",
                                    value: "\(totalAnalytics.attendees)",
                                    icon: "person.2.fill",
                                    chartType: .attendees,
                                    analytics: totalAnalytics,
                                    events: userEvents,
                                    analyticsManager: analyticsManager,
                                    onTap: { data in
                                        showingChart = data
                                    }
                                )
                                
                                ClickableStatBox(
                                    title: "Events Created",
                                    value: "\(userEvents.count)",
                                    icon: "calendar",
                                    chartType: .events,
                                    analytics: totalAnalytics,
                                    events: userEvents,
                                    analyticsManager: analyticsManager,
                                    onTap: { data in
                                        showingChart = data
                                    }
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 10)
                        
                        // Overall AI Feedback
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24))
                                    .foregroundColor(.getActiveRed)
                                
                                Text("Overall AI Feedback")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(totalAnalytics.aiFeedback)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                                .padding(16)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        
                        // Individual Event Analytics
                        if !userEvents.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Individual Event Analytics")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                
                                ForEach(userEvents) { event in
                                    EventAnalyticsCard(
                                        event: event,
                                        analytics: analyticsManager.getAnalytics(for: event.id, event: event),
                                        analyticsManager: analyticsManager,
                                        onChartTap: { chartData in
                                            showingChart = chartData
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.top, 10)
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                
                                Text("No Events Yet")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Text("Create your first event to see analytics")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 50)
                        }
                        
                        Spacer(minLength: 30)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
        .onAppear {
            // Initialize view counts for user events
            for event in userEvents {
                if analyticsManager.viewCounts[event.id] == nil {
                    // Simulate some views based on likes and attendees for demo
                    let estimatedViews = max(event.likedBy.count * 5, event.attending.count * 8, 10)
                    analyticsManager.viewCounts[event.id] = estimatedViews
                }
            }
        }
        .sheet(item: $showingChart) { chartData in
            AnalyticsChartView(
                title: chartData.title,
                chartType: chartData.chartType,
                data: chartData.data
            )
        }
    }
}

struct ChartDetailData: Identifiable {
    let id = UUID()
    let title: String
    let chartType: AnalyticsChartView.ChartType
    let data: AnalyticsChartView.ChartData
}

struct EventAnalyticsCard: View {
    let event: Event
    let analytics: EventAnalytics
    @ObservedObject var analyticsManager: AnalyticsManager
    @State private var isExpanded = false
    let onChartTap: (ChartDetailData) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(formatDate(event.date))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.getActiveRed)
                        .font(.system(size: 16))
                }
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                StatMini(title: "Views", value: "\(analytics.views)", icon: "eye.fill")
                StatMini(title: "Likes", value: "\(analytics.likes)", icon: "heart.fill")
                StatMini(title: "Attendees", value: "\(analytics.attendees)", icon: "person.2.fill")
            }
            
            // Expanded View
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    // Full Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 8),
                        GridItem(.flexible(), spacing: 8)
                    ], spacing: 8) {
                        ClickableStatBox(
                            title: "Views",
                            value: "\(analytics.views)",
                            icon: "eye.fill",
                            chartType: .views,
                            analytics: analytics,
                            events: [event],
                            analyticsManager: analyticsManager,
                            onTap: onChartTap
                        )
                        
                        ClickableStatBox(
                            title: "Likes",
                            value: "\(analytics.likes)",
                            icon: "heart.fill",
                            chartType: .likes,
                            analytics: analytics,
                            events: [event],
                            analyticsManager: analyticsManager,
                            onTap: onChartTap
                        )
                        
                        ClickableStatBox(
                            title: "Attendees",
                            value: "\(analytics.attendees)",
                            icon: "person.2.fill",
                            chartType: .attendees,
                            analytics: analytics,
                            events: [event],
                            analyticsManager: analyticsManager,
                            onTap: onChartTap
                        )
                        
                        ClickableStatBox(
                            title: "Shares",
                            value: "\(analytics.shares)",
                            icon: "square.and.arrow.up.fill",
                            chartType: .shares,
                            analytics: analytics,
                            events: [event],
                            analyticsManager: analyticsManager,
                            onTap: onChartTap
                        )
                    }
                    
                    // Ratings if available
                    if !analytics.ratings.isEmpty {
                        ClickableStatBox(
                            title: "Average Rating",
                            value: String(format: "%.1f", analytics.averageRating),
                            icon: "star.fill",
                            chartType: .ratings,
                            analytics: analytics,
                            events: [event],
                            analyticsManager: analyticsManager,
                            onTap: onChartTap
                        )
                        .padding(.top, 8)
                    }
                    
                    // AI Feedback
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundColor(.getActiveRed)
                            
                            Text("AI Feedback")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text(analytics.aiFeedback)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineSpacing(4)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct StatMini: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.getActiveRed)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.getActiveRed)
            
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

struct ClickableStatBox: View {
    let title: String
    let value: String
    let icon: String
    let chartType: AnalyticsChartView.ChartType
    let analytics: EventAnalytics
    let events: [Event]
    @ObservedObject var analyticsManager: AnalyticsManager
    let onTap: (ChartDetailData) -> Void
    
    var body: some View {
        Button(action: {
            let chartData = generateChartData()
            onTap(chartData)
        }) {
            StatBox(title: title, value: value, icon: icon)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func generateChartData() -> ChartDetailData {
        let chartData: AnalyticsChartView.ChartData
        
        switch chartType {
        case .views:
            chartData = generateViewsChartData()
        case .likes:
            chartData = generateLikesChartData()
        case .attendees:
            chartData = generateAttendeesChartData()
        case .ratings:
            chartData = generateRatingsChartData()
        case .events:
            chartData = generateEventsChartData()
        case .shares:
            chartData = generateSharesChartData()
        }
        
        return ChartDetailData(
            title: title,
            chartType: chartType,
            data: chartData
        )
    }
    
    private func generateViewsChartData() -> AnalyticsChartView.ChartData {
        var values: [(String, Int)] = []
        var total = 0
        
        for event in events {
            let views = analyticsManager.viewCounts[event.id] ?? 0
            if views > 0 {
                let shortTitle = event.title.count > 15 ? String(event.title.prefix(15)) + "..." : event.title
                values.append((shortTitle, views))
                total += views
            }
        }
        
        if values.isEmpty {
            values = [("No views yet", 0)]
        }
        
        return AnalyticsChartView.ChartData(values: values, currentTotal: total > 0 ? total : analytics.views)
    }
    
    private func generateLikesChartData() -> AnalyticsChartView.ChartData {
        var values: [(String, Int)] = []
        var total = 0
        
        for event in events {
            let likes = event.likedBy.count
            if likes > 0 {
                let shortTitle = event.title.count > 15 ? String(event.title.prefix(15)) + "..." : event.title
                values.append((shortTitle, likes))
                total += likes
            }
        }
        
        if values.isEmpty {
            values = [("No likes yet", 0)]
        }
        
        return AnalyticsChartView.ChartData(values: values, currentTotal: total > 0 ? total : analytics.likes)
    }
    
    private func generateAttendeesChartData() -> AnalyticsChartView.ChartData {
        var values: [(String, Int)] = []
        var total = 0
        
        for event in events {
            let attendees = event.attending.count
            if attendees > 0 {
                let shortTitle = event.title.count > 15 ? String(event.title.prefix(15)) + "..." : event.title
                values.append((shortTitle, attendees))
                total += attendees
            }
        }
        
        if values.isEmpty {
            values = [("No attendees yet", 0)]
        }
        
        return AnalyticsChartView.ChartData(values: values, currentTotal: total > 0 ? total : analytics.attendees)
    }
    
    private func generateRatingsChartData() -> AnalyticsChartView.ChartData {
        var ratingCounts: [Int: Int] = [1: 0, 2: 0, 3: 0, 4: 0, 5: 0]
        
        for rating in analytics.ratings {
            ratingCounts[rating.rating, default: 0] += 1
        }
        
        var values: [(String, Int)] = []
        for star in 1...5 {
            let count = ratingCounts[star] ?? 0
            values.append(("\(star) Star\(star > 1 ? "s" : "")", count))
        }
        
        let totalRatings = analytics.ratings.count
        return AnalyticsChartView.ChartData(values: values, currentTotal: totalRatings)
    }
    
    private func generateEventsChartData() -> AnalyticsChartView.ChartData {
        // Group events by category
        var categoryCounts: [String: Int] = [:]
        
        for event in events {
            categoryCounts[event.category.rawValue, default: 0] += 1
        }
        
        var values: [(String, Int)] = []
        for (category, count) in categoryCounts.sorted(by: { $0.value > $1.value }) {
            values.append((category, count))
        }
        
        return AnalyticsChartView.ChartData(values: values, currentTotal: events.count)
    }
    
    private func generateSharesChartData() -> AnalyticsChartView.ChartData {
        // Shares not tracked yet, return empty data
        return AnalyticsChartView.ChartData(values: [("No shares yet", 0)], currentTotal: 0)
    }
}

#Preview {
    AnalyticsView(eventManager: EventManager(), eventId: "test")
        .environmentObject(AuthenticationManager())
}

