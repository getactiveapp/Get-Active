import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var eventManager: EventManager
    @StateObject private var friendActivityManager = FriendActivityManager()
    @State private var selectedTab = 0
    @State private var showingProfile = false
    @State private var showingChatBot = false
    @State private var showingAllTodayEvents = false
    @State private var selectedEvent: Event?
    @State private var isRefreshing = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: DeviceSize.defaultSpacing) {
                        // Custom refresh indicator at the top
                        if isRefreshing {
                            HStack {
                                Spacer()
                                GetActiveLogoRefreshView()
                                    .frame(width: DeviceSize.iconSize * 2, height: DeviceSize.iconSize * 2)
                                    .padding(.vertical, DeviceSize.verticalPadding)
                                Spacer()
                            }
                        }
                        
                        // Header
                        ZStack {
                            // Centered title
                            Text("Home")
                                .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Right side buttons
                            HStack {
                                Spacer()
                                
                                // Guard Shield Icon and Profile button (top right)
                                HStack(spacing: DeviceSize.isPad ? 16 : 12) {
                                    Button(action: {
                                        showingChatBot = true
                                    }) {
                                        Image(systemName: "shield.fill")
                                            .font(.system(size: DeviceSize.iconSize + 4, weight: .semibold))
                                            .foregroundColor(.getActiveRed)
                                            .frame(width: DeviceSize.profileImageSize, height: DeviceSize.profileImageSize)
                                    }
                                    
                                    Button(action: {
                                        showingProfile = true
                                    }) {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: DeviceSize.profileImageSize, height: DeviceSize.profileImageSize)
                                            .overlay(
                                                Text("J")
                                                    .font(.system(size: DeviceSize.profileImageSize * 0.45, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, DeviceSize.isPad ? 20 : 10)
                        
                        // Search Bar
                        HStack {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: DeviceSize.iconSize))
                                
                                TextField("Search events...", text: $searchText)
                                    .font(.system(size: DeviceSize.bodyFontSize))
                                    .foregroundColor(.white)
                                    .focused($isSearchFocused)
                                    .autocorrectionDisabled()
                                
                                if !searchText.isEmpty {
                                    Button(action: {
                                        searchText = ""
                                        isSearchFocused = false
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gray)
                                            .font(.system(size: DeviceSize.iconSize))
                                    }
                                }
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding * 0.6)
                            .padding(.vertical, DeviceSize.searchBarHeight * 0.3)
                            .frame(height: DeviceSize.searchBarHeight)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, DeviceSize.isPad ? 16 : 12)
                        .padding(.bottom, DeviceSize.isPad ? 8 : 4)
                        
                        // Show search results if searching, otherwise show normal content
                        if !searchText.isEmpty {
                            searchResultsView
                        } else {
                            normalContentView
                        }
                    Spacer(minLength: 120)
                }
            }
            .background(
                RefreshControlReader(isRefreshing: $isRefreshing, onRefresh: {
                    await refreshData()
                })
            )
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingChatBot) {
            ChatBotView()
                .environmentObject(authManager)
                .environmentObject(eventManager)
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, eventManager: eventManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingAllTodayEvents) {
            AllTodayEventsView()
                .environmentObject(authManager)
                .environmentObject(eventManager)
        }
    }
    
    // Computed property for filtered search results
    private var filteredEvents: [Event] {
        guard !searchText.isEmpty else { return [] }
        
        let searchLower = searchText.lowercased()
        return eventManager.getAllEventsSorted().filter { event in
            event.title.lowercased().contains(searchLower) ||
            event.description.lowercased().contains(searchLower) ||
            event.location.lowercased().contains(searchLower) ||
            event.category.rawValue.lowercased().contains(searchLower) ||
            event.tags.contains { $0.lowercased().contains(searchLower) }
        }
    }
    
    // Search results view
    private var searchResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Search Results")
                    .font(.system(size: DeviceSize.titleFontSize, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(filteredEvents.count) found")
                    .font(.system(size: DeviceSize.isPad ? 14 : 12))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, DeviceSize.horizontalPadding)
            
            if filteredEvents.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 100)
                    
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: DeviceSize.isPad ? 60 : 50))
                        .foregroundColor(.gray)
                    
                    Text("No events found")
                        .font(.system(size: DeviceSize.titleFontSize, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Try searching with different keywords")
                        .font(.system(size: DeviceSize.bodyFontSize))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DeviceSize.horizontalPadding * 2)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                if DeviceSize.isPad {
                    LazyVGrid(columns: DeviceSize.adaptiveColumns(minWidth: 350), spacing: 20) {
                        ForEach(filteredEvents) { event in
                            AllEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "", onFavoriteToggle: {
                                if let userId = authManager.currentUser?.id {
                                    eventManager.updateFavoriteEvents(userId: userId)
                                }
                            })
                            .environmentObject(authManager)
                            .onTapGesture {
                                selectedEvent = event
                            }
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                } else {
                    VStack(spacing: 15) {
                        ForEach(filteredEvents) { event in
                            AllEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "", onFavoriteToggle: {
                                if let userId = authManager.currentUser?.id {
                                    eventManager.updateFavoriteEvents(userId: userId)
                                }
                            })
                            .environmentObject(authManager)
                            .onTapGesture {
                                selectedEvent = event
                            }
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                }
            }
        }
    }
    
    // Normal content view (existing content)
    private var normalContentView: some View {
        VStack(alignment: .leading, spacing: DeviceSize.defaultSpacing) {
                        // Featured Events
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Featured Events")
                                    .font(.system(size: DeviceSize.titleFontSize, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("Updated \(formatTime(Date()))")
                                    .font(.system(size: DeviceSize.isPad ? 14 : 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(eventManager.getFeaturedEvents()) { event in
                                        FeaturedEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "", onFavoriteToggle: {
                                            if let userId = authManager.currentUser?.id {
                                                eventManager.updateFavoriteEvents(userId: userId)
                                            }
                                        })
                                        .environmentObject(authManager)
                                        .onTapGesture {
                                            selectedEvent = event
                                        }
                                    }
                                }
                                .padding(.horizontal, DeviceSize.horizontalPadding)
                                .padding(.vertical, 5)
                            }
                        }
                        
                        // Friends' Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Friends' Activities")
                                .font(.system(size: DeviceSize.titleFontSize, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, DeviceSize.horizontalPadding)
                            
                            VStack(spacing: DeviceSize.isPad ? 16 : 12) {
                                ForEach(friendActivityManager.activities) { activity in
                                    FriendActivityRow(activity: activity, eventManager: eventManager)
                                        .environmentObject(authManager)
                                }
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                        }
                        
                        // Happening Today
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Happening Today")
                                    .font(.system(size: DeviceSize.titleFontSize, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("See all") {
                                    showingAllTodayEvents = true
                                }
                                .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                .foregroundColor(.getActiveRed)
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                            
                            // Use grid layout on iPad, vertical stack on iPhone
                            if DeviceSize.isPad {
                                LazyVGrid(columns: DeviceSize.adaptiveColumns(minWidth: 350), spacing: 20) {
                                    ForEach(eventManager.getEventsForToday()) { event in
                                        AllEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "", onFavoriteToggle: {
                                            if let userId = authManager.currentUser?.id {
                                                eventManager.updateFavoriteEvents(userId: userId)
                                            }
                                        })
                                        .environmentObject(authManager)
                                        .onTapGesture {
                                            selectedEvent = event
                                        }
                                    }
                                }
                                .padding(.horizontal, DeviceSize.horizontalPadding)
                            } else {
                                VStack(spacing: 15) {
                                    ForEach(eventManager.getEventsForToday()) { event in
                                        AllEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "", onFavoriteToggle: {
                                            if let userId = authManager.currentUser?.id {
                                                eventManager.updateFavoriteEvents(userId: userId)
                                            }
                                        })
                                        .environmentObject(authManager)
                                        .onTapGesture {
                                            selectedEvent = event
                                        }
                                    }
                                }
                                .padding(.horizontal, DeviceSize.horizontalPadding)
                            }
                        }
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        
        // Refresh events and friend activities
        await MainActor.run {
            eventManager.objectWillChange.send()
            friendActivityManager.objectWillChange.send()
            
            // Reload events
            if let userId = authManager.currentUser?.id {
                eventManager.updateFavoriteEvents(userId: userId)
            }
        }
        
        // Simulate refresh delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            isRefreshing = false
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"
        return formatter.string(from: date)
    }
}

struct FeaturedEventCard: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userId: String
    var onFavoriteToggle: (() -> Void)? = nil
    @State private var loadedImage: UIImage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                // Show image if available, otherwise show background color with icon
                if let loadedImage = loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: DeviceSize.featuredEventCardWidth, height: DeviceSize.featuredEventCardHeight)
                        .clipped()
                        .overlay(
                            // Dark overlay for text readability
                            LinearGradient(
                                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.5)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    // Background color based on event
                    RoundedRectangle(cornerRadius: 16)
                        .fill(backgroundColorForEvent(event))
                        .frame(width: DeviceSize.featuredEventCardWidth, height: DeviceSize.featuredEventCardHeight)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            // Check current state before toggling
                            let wasLiked = eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true
                            
                            eventManager.toggleFavorite(eventId: event.id, userId: userId)
                            
                            // Update user's favoriteEventIds based on new state (opposite of wasLiked)
                            if var user = authManager.currentUser {
                                if !wasLiked {
                                    // Now liked - add to favorites
                                    if !user.favoriteEventIds.contains(event.id) {
                                        user.favoriteEventIds.append(event.id)
                                    }
                                } else {
                                    // Now unliked - remove from favorites
                                    user.favoriteEventIds.removeAll { $0 == event.id }
                                }
                                authManager.updateUser(user)
                                // Ensure favorites list is updated
                                eventManager.updateFavoriteEvents(userId: userId)
                            }
                            onFavoriteToggle?()
                        }) {
                            Image(systemName: eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true ? "heart.fill" : "heart")
                                .foregroundColor(.white)
                                .font(.system(size: 18))
                                .padding(8)
                                .background(Color.getActiveBlack.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                    
                    Spacer()
                    
                    // Icon/Emoji centered at top (only if no image)
                    if loadedImage == nil, let iconName = event.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: DeviceSize.isPad ? 60 : 50))
                            .foregroundColor(.white)
                            .padding(.top, DeviceSize.isPad ? 24 : 20)
                    }
                    
                    Spacer()
                }
            }
            .frame(width: DeviceSize.featuredEventCardWidth, height: DeviceSize.featuredEventCardHeight)
            .cornerRadius(16)
            .onAppear {
                loadEventImage()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: DeviceSize.isPad ? 50 : 44, alignment: .topLeading)
                
                Text("\(formatDate(event.date)) • \(event.startTime) - \(event.endTime)")
                    .font(.system(size: DeviceSize.captionFontSize))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(event.location)
                    .font(.system(size: DeviceSize.captionFontSize))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    ForEach(event.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: DeviceSize.captionFontSize - 1, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, DeviceSize.isPad ? 12 : 10)
                            .padding(.vertical, DeviceSize.isPad ? 6 : 5)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(12)
                    }
                }
                
                if !event.attending.isEmpty {
                    Text("+\(event.attending.count) friends going")
                        .font(.system(size: DeviceSize.captionFontSize))
                        .foregroundColor(.gray)
                } else if event.likedBy.count > 0 {
                    Text("+\(event.likedBy.count) friends going")
                        .font(.system(size: DeviceSize.captionFontSize))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: DeviceSize.featuredEventCardWidth)
    }
    
    private func backgroundColorForEvent(_ event: Event) -> Color {
        switch event.backgroundColor {
        case "blue": return Color.blue
        case "green": return Color.green
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "teal": return Color.teal
        default: return Color.getActiveRed
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter.string(from: date)
    }
    
    private func loadEventImage() {
        // Load first image from customImages if available
        guard let customImages = event.customImages, !customImages.isEmpty else {
            return
        }
        
        Task {
            let imageName = customImages[0]
            if let image = await loadImageFromDocumentsAsync(fileName: imageName) {
                await MainActor.run {
                    self.loadedImage = image
                }
            }
        }
    }
    
    private func loadImageFromDocumentsAsync(fileName: String) async -> UIImage? {
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

struct EventCard: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userId: String
    var onFavoriteToggle: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColorForEvent(event))
                    .frame(width: 200, height: 150)
                
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                // Check current state before toggling
                                let wasLiked = eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true
                                
                                eventManager.toggleFavorite(eventId: event.id, userId: userId)
                                
                                // Update user's favoriteEventIds based on new state (opposite of wasLiked)
                                if var user = authManager.currentUser {
                                    if !wasLiked {
                                        // Now liked - add to favorites
                                        if !user.favoriteEventIds.contains(event.id) {
                                            user.favoriteEventIds.append(event.id)
                                        }
                                    } else {
                                        // Now unliked - remove from favorites
                                        user.favoriteEventIds.removeAll { $0 == event.id }
                                    }
                                    authManager.updateUser(user)
                                    // Ensure favorites list is updated
                                    eventManager.updateFavoriteEvents(userId: userId)
                                }
                                onFavoriteToggle?()
                            }) {
                                Image(systemName: eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true ? "heart.fill" : "heart")
                                    .foregroundColor(.white)
                                    .font(.system(size: 18))
                                    .padding(8)
                                    .background(Color.getActiveBlack.opacity(0.3))
                                    .clipShape(Circle())
                            }
                            .padding(10)
                        }
                        
                        Spacer()
                        
                        if let iconName = event.iconName {
                            Image(systemName: iconName)
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .padding(.bottom, 15)
                        }
                    }
                }
            
            Text(event.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(height: 40, alignment: .topLeading)
            
            Text(formatDate(event.date))
                .font(.system(size: 11))
                .foregroundColor(.gray)
            
            Text(event.location)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .frame(width: 200)
    }
    
    private func backgroundColorForEvent(_ event: Event) -> Color {
        switch event.backgroundColor {
        case "blue": return Color.blue
        case "green": return Color.green
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "teal": return Color.teal
        default: return Color.getActiveRed
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter.string(from: date)
    }
}

struct FriendActivityRow: View {
    let activity: FriendActivity
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedEvent: Event?
    @State private var showingFriendProfile = false
    @State private var showingChat = false
    @State private var showingJoinConfirmation = false
    
    var body: some View {
        HStack(alignment: .top, spacing: DeviceSize.defaultSpacing * 0.6) {
            // Profile Image
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: DeviceSize.profileImageSize, height: DeviceSize.profileImageSize)
                .overlay(
                    Text(String(activity.friendName.prefix(1)))
                        .font(.system(size: DeviceSize.profileImageSize * 0.4, weight: .semibold))
                        .foregroundColor(.white)
                )
                .onTapGesture {
                    showingFriendProfile = true
                }
            
            // Text content with proper spacing - using HStack with flexible wrapping
            VStack(alignment: .leading, spacing: 5) {
                // Use HStack with flexible layout to allow event name to wrap
                HStack(alignment: .top, spacing: 4) {
                    Text(activity.friendName)
                        .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(activity.activityType == .going ? "is going to" : "liked")
                        .font(.system(size: DeviceSize.bodyFontSize))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    // Event name that can wrap
                    Button(action: {
                        if let event = eventManager.events.first(where: { $0.id == activity.eventId }) {
                            selectedEvent = event
                        }
                    }) {
                        Text(activity.eventTitle)
                            .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                            .foregroundColor(.getActiveRed)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer(minLength: 0)
                }
                
                Text(timeAgo(from: activity.timestamp))
                    .font(.system(size: DeviceSize.captionFontSize))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                showingFriendProfile = true
            }
            
            // Action buttons - matching image layout
            HStack(spacing: 8) {
                if activity.activityType == .going {
                    Text("Join them")
                        .font(.system(size: DeviceSize.isPad ? 14 : 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, DeviceSize.isPad ? 16 : 12)
                        .padding(.vertical, DeviceSize.isPad ? 8 : 6)
                        .background(Color.getActiveRed)
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            handleJoinThem()
                        }
                }
                
                Image(systemName: "message")
                    .font(.system(size: 14))
                    .foregroundColor(.getActiveRed)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.getActiveRed, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingChat = true
                    }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event, eventManager: eventManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingFriendProfile) {
            FriendProfileView(friendName: activity.friendName, friendId: activity.friendId, eventManager: eventManager)
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showingChat) {
            NavigationView {
                ChatView(friendId: activity.friendId, friendName: activity.friendName)
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showingJoinConfirmation) {
            JoinConfirmationView(
                friendName: activity.friendName,
                eventTitle: activity.eventTitle
            )
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func handleJoinThem() {
        // Join them - Automatically like, RSVP, and add to attending
        guard let userId = authManager.currentUser?.id else { return }
        
        // Find event by title (more reliable than ID since events use auto-generated UUIDs)
        // First try by ID, then fall back to title matching
        var eventIndex: Int?
        
        if let index = eventManager.events.firstIndex(where: { $0.id == activity.eventId }) {
            eventIndex = index
        } else if let index = eventManager.events.firstIndex(where: { $0.title == activity.eventTitle }) {
            eventIndex = index
        }
        
        guard let index = eventIndex else {
            print("❌ Event not found: \(activity.eventTitle) (ID: \(activity.eventId))")
            return
        }
        
        let event = eventManager.events[index]
        
        // Automatically like the event
        if !eventManager.events[index].likedBy.contains(userId) {
            eventManager.events[index].likedBy.append(userId)
        }
        
        // Automatically RSVP to the event
        if !eventManager.events[index].rsvpBy.contains(userId) {
            eventManager.events[index].rsvpBy.append(userId)
        }
        
        // Add to attending (actually going)
        if !eventManager.events[index].attending.contains(userId) {
            eventManager.events[index].attending.append(userId)
        }
        
        // Update user's favoriteEventIds
        if var user = authManager.currentUser {
            if !user.favoriteEventIds.contains(event.id) {
                user.favoriteEventIds.append(event.id)
            }
            authManager.currentUser = user
        }
        
        // Schedule notifications
        let advanceMinutes = authManager.currentUser?.notificationAdvanceMinutes ?? 30
        NotificationManager.shared.scheduleNotification(
            for: eventManager.events[index],
            userId: userId,
            advanceMinutes: advanceMinutes
        )
        
        // Update favorites
        eventManager.updateFavoriteEvents(userId: userId)
        
        // Show join confirmation popup
        showingJoinConfirmation = true
    }
}

struct JoinConfirmationView: View {
    let friendName: String
    let eventTitle: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Checkmark icon
                    ZStack {
                        Circle()
                            .fill(Color.getActiveRed.opacity(0.2))
                            .frame(width: DeviceSize.isPad ? 120 : 100, height: DeviceSize.isPad ? 120 : 100)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: DeviceSize.isPad ? 70 : 60, weight: .bold))
                            .foregroundColor(.getActiveRed)
                    }
                    
                    // Message
                    VStack(spacing: 16) {
                        Text("You're joining")
                            .font(.system(size: DeviceSize.isPad ? 32 : 28, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(friendName) to")
                            .font(.system(size: DeviceSize.isPad ? 26 : 22, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(eventTitle)
                            .font(.system(size: DeviceSize.isPad ? 30 : 26, weight: .bold))
                            .foregroundColor(.getActiveRed)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                    }
                    
                    Spacer()
                    
                    // Action button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Got it!")
                            .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: DeviceSize.isPad ? 60 : 55)
                            .background(Color.getActiveRed)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.bottom, DeviceSize.isPad ? 40 : 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct AllEventCard: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userId: String
    var onFavoriteToggle: (() -> Void)? = nil
    @State private var loadedImage: UIImage?
    
    var body: some View {
        HStack(spacing: 15) {
            // Event Image or Icon/Color
            ZStack {
                if let loadedImage = loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColorForEvent(event))
                        .frame(width: 70, height: 70)
                    
                    if let iconName = event.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "calendar")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }
                }
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("\(formatDate(event.date)) • \(event.startTime) - \(event.endTime)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(event.location)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                // Tags
                if !event.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(event.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(6)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Like button
            Button(action: {
                let wasLiked = eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true
                
                eventManager.toggleFavorite(eventId: event.id, userId: userId)
                
                if var user = authManager.currentUser {
                    if !wasLiked {
                        if !user.favoriteEventIds.contains(event.id) {
                            user.favoriteEventIds.append(event.id)
                        }
                    } else {
                        user.favoriteEventIds.removeAll { $0 == event.id }
                    }
                    authManager.updateUser(user)
                    eventManager.updateFavoriteEvents(userId: userId)
                }
                onFavoriteToggle?()
            }) {
                Image(systemName: eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true ? "heart.fill" : "heart")
                    .foregroundColor(eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true ? .getActiveRed : .gray)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            loadEventImage()
        }
    }
    
    private func loadEventImage() {
        // Load first image from customImages if available
        guard let customImages = event.customImages, !customImages.isEmpty else {
            return
        }
        
        Task {
            let imageName = customImages[0]
            if let image = await loadImageFromDocumentsAsync(fileName: imageName) {
                await MainActor.run {
                    self.loadedImage = image
                }
            }
        }
    }
    
    private func loadImageFromDocumentsAsync(fileName: String) async -> UIImage? {
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
    
    private func backgroundColorForEvent(_ event: Event) -> Color {
        switch event.backgroundColor {
        case "blue": return Color.blue
        case "green": return Color.green
        case "purple": return Color.purple
        case "orange": return Color.orange
        case "teal": return Color.teal
        case "brown": return Color.brown
        case "pink": return Color.pink
        default: return Color.getActiveRed
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
        .environmentObject(EventManager())
}

