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
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Header
                        ZStack {
                            // Centered title
                            Text("Home")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Right side buttons
                            HStack {
                                Spacer()
                                
                                // Guard Shield Icon and Profile button (top right)
                                HStack(spacing: 12) {
                                    Button(action: {
                                        showingChatBot = true
                                    }) {
                                        Image(systemName: "shield.fill")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundColor(.getActiveRed)
                                            .frame(width: 40, height: 40)
                                    }
                                    
                                    Button(action: {
                                        showingProfile = true
                                    }) {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text("J")
                                                    .font(.system(size: 18, weight: .semibold))
                                                    .foregroundColor(.white)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // Featured Events
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Featured Events")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("Updated \(formatTime(Date()))")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            
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
                                .padding(.horizontal, 20)
                                .padding(.vertical, 5)
                            }
                        }
                        
                        // Friends' Activities
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Friends' Activities")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(friendActivityManager.activities) { activity in
                                    FriendActivityRow(activity: activity, eventManager: eventManager)
                                        .environmentObject(authManager)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Happening Today
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Happening Today")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("See all") {
                                    showingAllTodayEvents = true
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.getActiveRed)
                            }
                            .padding(.horizontal, 20)
                            
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
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingChatBot) {
                NavigationView {
                    ChatBotView()
                        .environmentObject(authManager)
                }
            }
            .sheet(item: $selectedEvent) { event in
                NavigationView {
                    EventDetailView(event: event, eventManager: eventManager)
                        .environmentObject(authManager)
                }
            }
                .sheet(isPresented: $showingAllTodayEvents) {
                    NavigationView {
                        AllTodayEventsView()
                            .environmentObject(authManager)
                            .environmentObject(eventManager)
                    }
                }
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                // Background color based on event
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColorForEvent(event))
                    .frame(width: 280, height: 200)
                
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
                                authManager.currentUser = user
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
                    
                    // Icon/Emoji centered at top
                    if let iconName = event.iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                    
                    Spacer()
                }
            }
            .frame(width: 280, height: 200)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: 44, alignment: .topLeading)
                
                Text("\(formatDate(event.date)) • \(event.startTime) - \(event.endTime)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text(event.location)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    ForEach(event.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gray.opacity(0.4))
                            .cornerRadius(12)
                    }
                }
                
                if !event.attending.isEmpty {
                    Text("+\(event.attending.count) friends going")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                } else if event.likedBy.count > 0 {
                    Text("+\(event.likedBy.count) friends going")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: 280)
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
                                    authManager.currentUser = user
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
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Profile Image
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(activity.friendName.prefix(1)))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Text content with proper spacing - using HStack with flexible wrapping
            VStack(alignment: .leading, spacing: 5) {
                // Use HStack with flexible layout to allow event name to wrap
                HStack(alignment: .top, spacing: 4) {
                    Text(activity.friendName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(activity.activityType == .going ? "is going to" : "liked")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    // Event name that can wrap
                    Button(action: {
                        // Stop propagation to parent tap gesture
                        if let event = eventManager.events.first(where: { $0.id == activity.eventId }) {
                            selectedEvent = event
                        }
                    }) {
                        Text(activity.eventTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.getActiveRed)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineLimit(2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .highPriorityGesture(TapGesture().onEnded {
                        if let event = eventManager.events.first(where: { $0.id == activity.eventId }) {
                            selectedEvent = event
                        }
                    })
                    
                    Spacer(minLength: 0)
                }
                
                Text(timeAgo(from: activity.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Action buttons - matching image layout
            HStack(spacing: 8) {
                if activity.activityType == .going {
                    Button(action: {
                        // Stop propagation to parent tap gesture
                        if let event = eventManager.events.first(where: { $0.id == activity.eventId }) {
                            selectedEvent = event
                        }
                    }) {
                        Text("Join them")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.getActiveRed)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .highPriorityGesture(TapGesture().onEnded {
                        if let event = eventManager.events.first(where: { $0.id == activity.eventId }) {
                            selectedEvent = event
                        }
                    })
                }
                
                Button(action: {
                    // Message action - navigate to direct chat with this friend
                    showingChat = true
                }) {
                    Image(systemName: "message")
                        .font(.system(size: 14))
                        .foregroundColor(.getActiveRed)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color.getActiveRed, lineWidth: 1)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            showingFriendProfile = true
        }
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                EventDetailView(event: event, eventManager: eventManager)
                    .environmentObject(authManager)
            }
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
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AllEventCard: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userId: String
    var onFavoriteToggle: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 15) {
            // Event Icon/Color
            ZStack {
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
                    authManager.currentUser = user
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

