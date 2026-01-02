import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var eventManager: EventManager
    @State private var showingProfile = false
    @State private var showingChatBot = false
    @State private var selectedEvent: Event?
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                    // Header - Always at the top
                    ZStack {
                        // Centered title
                        Text("Favorites")
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
                                        .font(.system(size: DeviceSize.isPad ? 28 : 24, weight: .semibold))
                                        .foregroundColor(.getActiveRed)
                                        .frame(width: DeviceSize.isPad ? 48 : 40, height: DeviceSize.isPad ? 48 : 40)
                                }
                                
                                Button(action: {
                                    showingProfile = true
                                }) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: DeviceSize.isPad ? 48 : 40, height: DeviceSize.isPad ? 48 : 40)
                                        .overlay(
                                            Text("J")
                                                .font(.system(size: DeviceSize.isPad ? 22 : 18, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, DeviceSize.isPad ? 15 : 5)
                    .padding(.bottom, DeviceSize.isPad ? 20 : 10)
                
                    // Content below header
                    if eventManager.favoriteEvents.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "heart")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            
                            Text("No Favorites Yet")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Like events from the home tab to see them here")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            // Use grid layout on iPad, vertical stack on iPhone
                            if DeviceSize.isPad {
                                LazyVGrid(columns: DeviceSize.adaptiveColumns(minWidth: 400), spacing: 20) {
                                    ForEach(eventManager.favoriteEvents) { event in
                                        FavoriteEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "", onFavoriteToggle: {
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
                                .padding(.top, 10)
                                .padding(.bottom, 100)
                            } else {
                                VStack(spacing: 15) {
                                    ForEach(eventManager.favoriteEvents) { event in
                                        FavoriteEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "", onFavoriteToggle: {
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
                                .padding(.top, 10)
                                .padding(.bottom, 100)
                            }
                        }
                    }
                }
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
            .onAppear {
                if let userId = authManager.currentUser?.id {
                    syncFavoritesWithUser(userId: userId)
                    eventManager.updateFavoriteEvents(userId: userId)
                }
            }
            .onChange(of: authManager.currentUser?.favoriteEventIds) { oldValue, newValue in
                if let userId = authManager.currentUser?.id {
                    syncFavoritesWithUser(userId: userId)
                    eventManager.updateFavoriteEvents(userId: userId)
                }
            }
            .onChange(of: eventManager.events) { oldValue, newValue in
                if let userId = authManager.currentUser?.id {
                    eventManager.updateFavoriteEvents(userId: userId)
                }
            }
            .onChange(of: authManager.currentUser?.id) { oldValue, newValue in
                if let userId = authManager.currentUser?.id {
                    syncFavoritesWithUser(userId: userId)
                    eventManager.updateFavoriteEvents(userId: userId)
                }
        }
    }
    
    private func syncFavoritesWithUser(userId: String) {
        guard let favoriteEventIds = authManager.currentUser?.favoriteEventIds else { return }
        
        // Ensure all favoriteEventIds are in likedBy arrays
        for eventId in favoriteEventIds {
            if let index = eventManager.events.firstIndex(where: { $0.id == eventId }) {
                if !eventManager.events[index].likedBy.contains(userId) {
                    eventManager.events[index].likedBy.append(userId)
                }
            }
        }
    }
}

struct FavoriteEventCard: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userId: String
    var onFavoriteToggle: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image/Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColorForEvent(event))
                    .frame(width: 80, height: 80)
                
                if let iconName = event.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "calendar")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text("\(formatDate(event.date)) • \(event.startTime) - \(event.endTime)")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(event.location)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                // Show liked or RSVP'd indicator
                if event.likedBy.contains(userId) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                        Text("Liked")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.getActiveRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.getActiveRed.opacity(0.2))
                    .cornerRadius(6)
                } else if event.rsvpBy.contains(userId) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("I'm Going")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.getActiveRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.getActiveRed.opacity(0.2))
                    .cornerRadius(6)
                }
                
                HStack(spacing: 6) {
                    ForEach(event.tags.prefix(2), id: \.self) { tag in
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
            
            Spacer(minLength: 8)
            
            Button(action: {
                // Stop event propagation when clicking the heart button
                // Remove from both liked and RSVP'd
                if let index = eventManager.events.firstIndex(where: { $0.id == event.id }) {
                    // Remove from liked
                    eventManager.events[index].likedBy.removeAll { $0 == userId }
                    // Remove from RSVP'd
                    eventManager.events[index].rsvpBy.removeAll { $0 == userId }
                    eventManager.events[index].attending.removeAll { $0 == userId }
                    
                    // Cancel notifications
                    NotificationManager.shared.cancelNotifications(for: event.id, userId: userId)
                }
                
                // Update user's favoriteEventIds
                if var user = authManager.currentUser {
                    user.favoriteEventIds.removeAll { $0 == event.id }
                    authManager.currentUser = user
                }
                
                // Update favorites list
                eventManager.updateFavoriteEvents(userId: userId)
                onFavoriteToggle?()
            }) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.getActiveRed)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
    FavoritesView()
        .environmentObject(AuthenticationManager())
}

