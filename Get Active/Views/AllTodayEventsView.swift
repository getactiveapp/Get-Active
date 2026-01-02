import SwiftUI

struct AllTodayEventsView: View {
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedEvent: Event?
    
    var allEvents: [Event] {
        eventManager.getAllEventsSorted()
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
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("All Events")
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
                .padding(.bottom, DeviceSize.isPad ? 20 : 10)
                
                if allEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No Events")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Check back later for upcoming events!")
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
                                ForEach(allEvents) { event in
                                    Button(action: {
                                        selectedEvent = event
                                    }) {
                                        TodayEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "")
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                            .padding(.top, 10)
                            .padding(.bottom, 100)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(allEvents) { event in
                                    Button(action: {
                                        selectedEvent = event
                                    }) {
                                        TodayEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "")
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
        .navigationBarHidden(true)
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                EventDetailView(event: event, eventManager: eventManager)
                    .environmentObject(authManager)
            }
        }
    }
}

struct TodayEventCard: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    let userId: String
    
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
                    
                    Text("\(event.startTime) - \(event.endTime)")
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
                
                // Status indicators
                HStack(spacing: 8) {
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
                    }
                    
                    if event.attending.contains(userId) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                            Text("I'm Going")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(6)
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
            }) {
                Image(systemName: eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true ? "heart.fill" : "heart")
                    .foregroundColor(eventManager.events.first(where: { $0.id == event.id })?.likedBy.contains(userId) == true ? .getActiveRed : .gray)
                    .font(.system(size: 20))
            }
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
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
}

#Preview {
    AllTodayEventsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(EventManager())
}

