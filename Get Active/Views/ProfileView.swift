import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var eventManager: EventManager
    @StateObject private var calendarManager = CalendarManager()
    @State private var showingSettings = false
    @State private var showingEventPost = false
    @State private var showingAnalytics = false
    @State private var showingMembership = false
    @State private var showingPrivacy = false
    @State private var showingMyEvents = false
    @State private var showingMessages = false
    @State private var showingFriends = false
    @State private var showingHelp = false
    @State private var showingCalendarPermission = false
    @State private var selectedEvent: Event?
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header with back button
                        HStack {
                            Button(action: {
                                dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Text("Profile")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Invisible button for balance
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20))
                                .foregroundColor(.clear)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Profile Header with Red Background
                        ZStack {
                            Color.getActiveRed
                                .frame(height: 300)
                            
                            VStack(spacing: 15) {
                                // Profile Image
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(String((authManager.currentUser?.name.prefix(1) ?? "U")))
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                // Name
                                Text(authManager.currentUser?.name ?? "User")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                // University and Year
                                HStack(spacing: 5) {
                                    Text(authManager.currentUser?.university ?? "")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Text("•")
                                        .foregroundColor(.white)
                                    
                                    Text(authManager.currentUser?.year ?? "")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                    
                                    Button(action: {
                                        // Add friend functionality
                                        showingFriends = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.getActiveRed)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }
                                }
                                
                                // Stats
                                HStack(spacing: 5) {
                                    Text("\(authManager.currentUser?.friends.count ?? 0) Friends")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    
                                    Text("•")
                                        .foregroundColor(.white)
                                    
                                    Text("\(getEventsThisWeek()) Events This Week")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, 50)
                        }
                        
                        // Make a Post Button
                        Button(action: {
                            if authManager.currentUser?.accountType == .activeMember {
                                showingEventPost = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18))
                                Text("Make a Post")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.getActiveRed)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .opacity(authManager.currentUser?.accountType == .activeMember ? 1.0 : 0.0)
                        .disabled(authManager.currentUser?.accountType != .activeMember)
                        
                        // Resources Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resources")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                ResourceRow(text: "Student Health Services", url: "https://www.centralstate.edu/student-life/health-services")
                                ResourceRow(text: "Mental Health America: mhanational.org", url: "https://mhanational.org")
                                ResourceRow(text: "NAMI (National Alliance on Mental Illness): nami.org", url: "https://nami.org")
                            }
                            .padding(16)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 25)
                        
                        // Calendar Integration
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Calendar")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                Task {
                                    if calendarManager.authorizationStatus == .notDetermined || calendarManager.authorizationStatus == .denied {
                                        showingCalendarPermission = true
                                        let granted = await calendarManager.requestCalendarAccess()
                                        if granted {
                                            showingCalendarPermission = false
                                        }
                                    } else if calendarManager.isCalendarLinked {
                                        // Already linked
                                        showingCalendarPermission = false
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: calendarManager.isCalendarLinked ? "checkmark.circle.fill" : "calendar.badge.plus")
                                        .font(.system(size: 20))
                                        .foregroundColor(.getActiveRed)
                                    
                                    Text(calendarManager.isCalendarLinked ? "Calendar Linked" : "Link to Calendar")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 25)
                        
                        // Stats Cards
                        HStack(spacing: 12) {
                            StatCard(icon: "person.3.fill", value: "\(authManager.currentUser?.friends.count ?? 0)", label: "Friends") {
                                showingFriends = true
                            }
                            StatCard(icon: "clock.fill", value: "\(getUpcomingEvents().count)", label: "Upcoming") {
                                // Show upcoming events
                            }
                            StatCard(icon: "calendar", value: "\(getEventsThisWeek())", label: "This Week") {
                                // Show this week's events
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 25)
                        
                        // Events Starting Soon
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Events Starting Soon")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 10) {
                                ForEach(Array(getUpcomingEvents().prefix(3))) { event in
                                    EventTimeCard(
                                        timeRemaining: timeRemaining(for: event),
                                        title: event.title,
                                        location: event.location,
                                        event: event
                                    )
                                    .onTapGesture {
                                        selectedEvent = event
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 25)
                        
                        // Mental Awareness Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mental Awareness")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                MentalAwarenessRow(
                                    icon: "heart.text.square.fill",
                                    title: "Wellness Check-In",
                                    description: "Take a moment to check in with yourself",
                                    color: .getActiveRed
                                ) {
                                    // Open wellness check-in
                                    if let url = URL(string: "https://mhanational.org/screening-tools") {
                                        openURL(url)
                                    }
                                }
                                
                                MentalAwarenessRow(
                                    icon: "brain.head.profile",
                                    title: "Mental Health Resources",
                                    description: "Access support and counseling services",
                                    color: .getActiveRed
                                ) {
                                    // Open mental health resources
                                    if let url = URL(string: "https://www.centralstate.edu/student-life/health-services") {
                                        openURL(url)
                                    }
                                }
                                
                                MentalAwarenessRow(
                                    icon: "person.2.fill",
                                    title: "Support Groups",
                                    description: "Connect with peer support networks",
                                    color: .getActiveRed
                                ) {
                                    // Show support groups
                                    showingHelp = true
                                }
                                
                                MentalAwarenessRow(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Crisis Support",
                                    description: "988 Suicide & Crisis Lifeline",
                                    color: .getActiveRed
                                ) {
                                    // Call crisis support
                                    if let url = URL(string: "tel:988") {
                                        openURL(url)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 25)
                        
                        // Settings Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Settings")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                if authManager.currentUser?.accountType == .activeMember {
                                    SettingsRow(icon: "doc.text.fill", title: "My Membership", color: .getActiveRed) {
                                        showingMembership = true
                                    }
                                    SettingsRow(icon: "chart.bar.fill", title: "Event Analytics", color: .getActiveRed) {
                                        showingAnalytics = true
                                    }
                                }
                                
                                SettingsRow(icon: "shield.fill", title: "Privacy", color: .getActiveRed) {
                                    showingPrivacy = true
                                }
                                
                                SettingsRow(icon: "trash.fill", title: "My Events (\(getMyEventsCount()))", color: .getActiveRed) {
                                    showingMyEvents = true
                                }
                                
                                SettingsRow(icon: "message.fill", title: "Messages", color: .getActiveRed) {
                                    showingMessages = true
                                }
                                
                                SettingsRow(icon: "person.2.fill", title: "Friends", color: .getActiveRed) {
                                    showingFriends = true
                                }
                                
                                SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .getActiveRed) {
                                    showingHelp = true
                                }
                                
                                SettingsRow(icon: "arrow.right.square.fill", title: "Logout", color: .getActiveRed, isLogout: true) {
                                    authManager.logout()
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEventPost) {
                EventPostingView(eventManager: eventManager)
            }
            .sheet(isPresented: $showingAnalytics) {
                if let firstEvent = eventManager.events.first {
                    AnalyticsView(eventManager: eventManager, eventId: firstEvent.id)
                }
            }
            .sheet(isPresented: $showingMembership) {
                MembershipView()
            }
            .sheet(isPresented: $showingPrivacy) {
                PrivacyView()
            }
            .sheet(isPresented: $showingMyEvents) {
                MyEventsView(eventManager: eventManager, authManager: authManager)
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingMessages) {
                MessagesView()
            }
            .sheet(isPresented: $showingFriends) {
                FriendsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingHelp) {
                HelpSupportView()
            }
            .sheet(item: $selectedEvent) { event in
                NavigationView {
                    EventDetailView(event: event, eventManager: eventManager)
                        .environmentObject(authManager)
                }
            }
            .alert("Calendar Access", isPresented: $showingCalendarPermission) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Get Active needs access to your calendar to add events. Please enable calendar access in Settings.")
            }
        }
    }
    
    private func getEventsThisWeek() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now)!
        return eventManager.events.filter { $0.date >= now && $0.date <= weekFromNow }.count
    }
    
    private func getMyEventsCount() -> Int {
        guard let userId = authManager.currentUser?.id else { return 0 }
        return eventManager.events.filter { $0.createdBy == userId }.count
    }
    
    private func getUpcomingEvents() -> [Event] {
        let now = Date()
        return eventManager.events
            .filter { $0.date >= now }
            .sorted { $0.date < $1.date }
    }
    
    private func timeRemaining(for event: Event) -> String {
        let now = Date()
        let timeInterval = event.date.timeIntervalSince(now)
        
        if timeInterval < 0 {
            return "Past"
        }
        
        let hours = Int(timeInterval / 3600)
        let days = hours / 24
        let remainingHours = hours % 24
        
        if days > 0 {
            return "\(days)d \(remainingHours)h"
        } else {
            return "\(hours)h"
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.getActiveRed)
                
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct EventTimeCard: View {
    let timeRemaining: String
    let title: String
    let location: String
    let event: Event?
    @StateObject private var calendarManager = CalendarManager()
    
    init(timeRemaining: String, title: String, location: String, event: Event? = nil) {
        self.timeRemaining = timeRemaining
        self.title = title
        self.location = location
        self.event = event
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Text(timeRemaining)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.getActiveRed)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(location)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if let event = event {
                Button(action: {
                    Task {
                        if !calendarManager.isCalendarLinked {
                            _ = await calendarManager.requestCalendarAccess()
                        }
                        if calendarManager.isCalendarLinked {
                            _ = await calendarManager.addEventToCalendar(event)
                        }
                    }
                }) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18))
                        .foregroundColor(.getActiveRed)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ResourceRow: View {
    let text: String
    let url: String
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                openURL(url)
            }
        }) {
            HStack {
                Text("•")
                    .foregroundColor(.white)
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    var isLogout: Bool = false
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isLogout ? color : .white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.gray.opacity(0.1))
            .overlay(
                Group {
                    if isLogout {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: 1)
                    }
                }
            )
            .cornerRadius(12)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}

