import SwiftUI
import CoreLocation

struct UniversityEventsView: View {
    let university: University
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedEvent: Event?
    
    var universityEvents: [Event] {
        eventManager.getEventsForUniversity(university)
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
                    
                    Text(university.name)
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
                
                // University Info Card
                VStack(spacing: 12) {
                    // University Icon
                    ZStack {
                        Circle()
                            .fill(Color.getActiveRed)
                            .frame(width: 80, height: 80)
                        
                        Text(university.abbreviation)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text(university.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 15) {
                        HStack(spacing: 5) {
                            Image(systemName: "mappin")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text(String(format: "%.1f miles away", university.distance))
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        
                        HStack(spacing: 5) {
                            Image(systemName: "calendar")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                            
                            Text("\(universityEvents.count) events")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Events List
                if universityEvents.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No events found")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("This university doesn't have any events listed yet.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 40)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Events at \(university.name)")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            VStack(spacing: 12) {
                                ForEach(universityEvents) { event in
                                    Button(action: {
                                        selectedEvent = event
                                    }) {
                                        UniversityEventCard(event: event, eventManager: eventManager, userId: authManager.currentUser?.id ?? "")
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
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
                EventDetailView(event: event, eventManager: eventManager, isFromOtherUniversity: true)
                    .environmentObject(authManager)
            }
        }
    }
}

struct UniversityEventCard: View {
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
                    .frame(width: 60, height: 60)
                
                if let iconName = event.iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(formatDate(event.date))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text("\(event.startTime) - \(event.endTime)")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 5) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(event.location)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .lineLimit(1)
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
                    // Ensure favorites list is updated
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
    UniversityEventsView(
        university: University(
            name: "Wright State University",
            abbreviation: "W",
            location: CLLocationCoordinate2D(latitude: 39.7844, longitude: -84.0556),
            distance: 8.5,
            eventCount: 15
        ),
        eventManager: EventManager()
    )
    .environmentObject(AuthenticationManager())
}

