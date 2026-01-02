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
    @State private var showingAccountSettings = false
    @State private var showingFriendFinderSettings = false
    @State private var showingNotificationSettings = false
    @State private var showingDeleteAccountAlert = false
    @State private var selectedEvent: Event?
    @State private var isRefreshing = false
    @State private var profileImage: UIImage?
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    private var mentalHealthResources: MentalHealthResources {
        let university = authManager.currentUser?.university ?? ""
        return MentalHealthResourcesManager.shared.getResources(for: university)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Custom refresh indicator at the top
                        if isRefreshing {
                            HStack {
                                Spacer()
                                GetActiveLogoRefreshView()
                                    .frame(width: 50, height: 50)
                                    .padding(.vertical, 10)
                                Spacer()
                            }
                        }
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
                                .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Invisible button for balance
                            Image(systemName: "chevron.left")
                                .font(.system(size: DeviceSize.isPad ? 24 : 20))
                                .foregroundColor(.clear)
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, DeviceSize.isPad ? 20 : 10)
                        
                        // Profile Header with Red Background
                        ZStack {
                            Color.getActiveRed
                                .frame(height: DeviceSize.isPad ? ((authManager.currentUser?.bio.isEmpty == false) ? 420 : 360) : ((authManager.currentUser?.bio.isEmpty == false) ? 360 : 300))
                            
                            VStack(spacing: DeviceSize.isPad ? 20 : 15) {
                                // Profile Image
                                ZStack {
                                    if let profileImage = profileImage {
                                        Image(uiImage: profileImage)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                    }
                                    
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                }
                                .frame(width: DeviceSize.isPad ? 120 : 100, height: DeviceSize.isPad ? 120 : 100)
                                .clipShape(Circle())
                                .overlay(
                                    // Fallback to initial if no image
                                    Group {
                                        if profileImage == nil {
                                            Text(String((authManager.currentUser?.name.prefix(1) ?? "U")))
                                                .font(.system(size: DeviceSize.isPad ? 50 : 40, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                )
                                
                                // Name
                                Text(authManager.currentUser?.name ?? "User")
                                    .font(.system(size: DeviceSize.isPad ? 34 : 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                // University and Year
                                HStack(spacing: 5) {
                                    Text(authManager.currentUser?.university ?? "")
                                        .font(.system(size: DeviceSize.isPad ? 18 : 16))
                                        .foregroundColor(.white)
                                    
                                    Text("•")
                                        .foregroundColor(.white)
                                    
                                    Text(authManager.currentUser?.year ?? "")
                                        .font(.system(size: DeviceSize.isPad ? 18 : 16))
                                        .foregroundColor(.white)
                                    
                                    Button(action: {
                                        // Add friend functionality
                                        showingFriends = true
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.getActiveRed)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .font(.system(size: DeviceSize.isPad ? 20 : 16))
                                    }
                                }
                                
                                // Bio
                                if let bio = authManager.currentUser?.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.system(size: DeviceSize.isPad ? 16 : 14))
                                        .foregroundColor(.white.opacity(0.9))
                                        .multilineTextAlignment(.center)
                                        .lineLimit(DeviceSize.isPad ? 4 : 3)
                                        .padding(.horizontal, DeviceSize.isPad ? 40 : 20)
                                        .padding(.top, DeviceSize.isPad ? 8 : 5)
                                }
                                
                                // Stats
                                HStack(spacing: 5) {
                                    Text("\(authManager.currentUser?.friends.count ?? 0) Friends")
                                        .font(.system(size: DeviceSize.isPad ? 16 : 14))
                                        .foregroundColor(.white)
                                    
                                    Text("•")
                                        .foregroundColor(.white)
                                    
                                    Text("\(getEventsThisWeek()) Events This Week")
                                        .font(.system(size: DeviceSize.isPad ? 16 : 14))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.top, DeviceSize.isPad ? 60 : 50)
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
                                    if let url = URL(string: mentalHealthResources.wellnessCheckInURL) {
                                        openURL(url)
                                    }
                                }
                                
                                MentalAwarenessRow(
                                    icon: "brain.head.profile",
                                    title: "Mental Health Resources",
                                    description: "Access support and counseling services",
                                    color: .getActiveRed
                                ) {
                                    // Open mental health resources - university specific
                                    if let url = URL(string: mentalHealthResources.mentalHealthResourcesURL) {
                                        openURL(url)
                                    }
                                }
                                
                                MentalAwarenessRow(
                                    icon: "person.2.fill",
                                    title: "Support Groups",
                                    description: "Connect with peer support networks",
                                    color: .getActiveRed
                                ) {
                                    // Open support groups - university specific
                                    if let url = URL(string: mentalHealthResources.supportGroupsURL) {
                                        openURL(url)
                                    }
                                }
                                
                                MentalAwarenessRow(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Crisis Support",
                                    description: "988 Suicide & Crisis Lifeline",
                                    color: .getActiveRed
                                ) {
                                    // Call crisis support
                                    if let url = URL(string: "tel:\(mentalHealthResources.crisisSupportPhone)") {
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
                                SettingsRow(icon: "person.circle.fill", title: "Account Settings", color: .getActiveRed) {
                                    showingAccountSettings = true
                                }
                                
                                SettingsRow(icon: "person.2.fill", title: "Friend Finder Profile", color: .getActiveRed, action: {
                                    showingFriendFinderSettings = true
                                })
                                
                                SettingsRow(icon: "bell.fill", title: "Notification Settings", color: .getActiveRed, action: {
                                    showingNotificationSettings = true
                                })
                                
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
                                
                                // Only show "My Events" for Active Members
                                if authManager.currentUser?.accountType == .activeMember {
                                    SettingsRow(icon: "trash.fill", title: "My Events (\(getMyEventsCount()))", color: .getActiveRed) {
                                        showingMyEvents = true
                                    }
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
                                
                                SettingsRow(icon: "trash.fill", title: "Delete Account", color: .red, isLogout: false) {
                                    showingDeleteAccountAlert = true
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
            .background(
                RefreshControlReader(isRefreshing: $isRefreshing, onRefresh: {
                    await refreshData()
                })
            )
            .onAppear {
                loadProfileImage()
            }
            .onChange(of: authManager.currentUser?.profileImageName) { _, _ in
                loadProfileImage()
            }
            .onChange(of: authManager.currentUser?.bio) { _, _ in
                // Bio changes are automatically reflected since we're reading from currentUser
            }
            .sheet(isPresented: $showingEventPost) {
                EventPostingView(eventManager: eventManager)
            }
            .sheet(isPresented: $showingAnalytics) {
                if let firstEvent = eventManager.events.first(where: { $0.createdBy == authManager.currentUser?.id }) {
                    AnalyticsView(eventManager: eventManager, eventId: firstEvent.id)
                        .environmentObject(authManager)
                } else if let firstEvent = eventManager.events.first {
                    AnalyticsView(eventManager: eventManager, eventId: firstEvent.id)
                        .environmentObject(authManager)
                } else {
                    AnalyticsView(eventManager: eventManager, eventId: "")
                        .environmentObject(authManager)
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
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    authManager.deleteAccount { success in
                        if success {
                            // Account deleted, user will be logged out automatically
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.")
            }
            .sheet(isPresented: $showingAccountSettings) {
                AccountSettingsView()
                    .environmentObject(authManager)
                    .onDisappear {
                        // Reload profile image when account settings is dismissed
                        loadProfileImage()
                    }
            }
            .sheet(isPresented: $showingFriendFinderSettings) {
                FriendFinderSettingsView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingNotificationSettings) {
                NotificationSettingsView()
                    .environmentObject(authManager)
                    .environmentObject(eventManager)
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
    
    private func refreshData() async {
        isRefreshing = true
        
        // Refresh events
        await MainActor.run {
            eventManager.objectWillChange.send()
            if let userId = authManager.currentUser?.id {
                eventManager.updateFavoriteEvents(userId: userId)
            }
            // Reload profile image
            loadProfileImage()
        }
        
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            isRefreshing = false
        }
    }
    
    private func loadProfileImage() {
        guard let imageName = authManager.currentUser?.profileImageName else {
            profileImage = nil
            return
        }
        
        Task {
            if let image = await loadProfileImageFromDocuments(fileName: imageName) {
                await MainActor.run {
                    profileImage = image
                }
            } else {
                await MainActor.run {
                    profileImage = nil
                }
            }
        }
    }
    
    private func loadProfileImageFromDocuments(fileName: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let fileManager = FileManager.default
                let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let filePath = documentsPath.appendingPathComponent(fileName)
                
                do {
                    let imageData = try Data(contentsOf: filePath)
                    if let image = UIImage(data: imageData) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
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

