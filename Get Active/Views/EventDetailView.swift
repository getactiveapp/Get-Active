import SwiftUI
import UIKit

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject var eventManager: EventManager
    @Environment(\.dismiss) var dismiss
    @State private var isLiked = false
    @State private var hasRSVPd = false
    @State private var isGoing = false
    @State private var isHere = false
    @State private var showHerePopup = false
    @State private var loadedImages: [String: UIImage] = [:] // Cache for loaded images
    var isFromOtherUniversity: Bool = false // Flag to indicate if event is from another university
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Event Banner/Image
                    ZStack {
                        // Show custom uploaded images if available
                        if let customImages = event.customImages, !customImages.isEmpty {
                            if let firstImage = loadedImages[customImages[0]] {
                                Image(uiImage: firstImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                            } else {
                                // Show placeholder while loading
                                Rectangle()
                                    .fill(backgroundColorForEvent(event))
                                    .frame(height: 250)
                                    .overlay(
                                        ProgressView()
                                            .tint(.white)
                                    )
                            }
                        } else {
                            // Background color based on event
                            Rectangle()
                                .fill(backgroundColorForEvent(event))
                                .frame(height: 250)
                            
                            // Icon in center
                            if let iconName = event.iconName {
                                Image(systemName: iconName)
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "calendar")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                    // Display all custom images in a scrollable gallery
                    if let customImages = event.customImages, customImages.count > 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(customImages, id: \.self) { imageName in
                                    if let image = loadedImages[imageName] {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 150)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        // Placeholder while loading
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 200, height: 150)
                                            .overlay(
                                                ProgressView()
                                                    .tint(.white)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 15)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Event Title
                        Text(event.title)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Organizer
                        if !event.createdBy.isEmpty {
                            Text("by \(event.createdBy)")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 20)
                        }
                        
                        // Like button (for all users)
                        HStack(spacing: 12) {
                            Button(action: {
                                toggleLike()
                            }) {
                                HStack {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 18))
                                    Text("Like")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.getActiveRed)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.getActiveRed, lineWidth: 1)
                                )
                            }
                            
                            // Delete button (only for Active Members who created the event)
                            if authManager.currentUser?.accountType == .activeMember && event.createdBy == authManager.currentUser?.id {
                                Button(action: {
                                    // Delete event
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                            .font(.system(size: 18))
                                        Text("Delete")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.getActiveRed)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.getActiveRed, lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Date & Time Section
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "calendar")
                                .font(.system(size: 20))
                                .foregroundColor(.getActiveRed)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(formatFullDate(event.date))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text("\(event.startTime) - \(event.endTime)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Location Section
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "mappin")
                                .font(.system(size: 20))
                                .foregroundColor(.getActiveRed)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 5) {
                                Text(event.location)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    // View on map
                                }) {
                                    Text("View on map")
                                        .font(.system(size: 14))
                                        .foregroundColor(.getActiveRed)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // Attendees Section
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "person.2")
                                .font(.system(size: 20))
                                .foregroundColor(.getActiveRed)
                                .frame(width: 30)
                            
                            Text("\(event.attending.count) people going")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text(event.description.isEmpty ? "Join us for an exciting event!" : event.description)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 20)
                        
                        // Tags Section
                        if !event.tags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Tags")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(event.tags, id: \.self) { tag in
                                            Text(tag)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 8)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Friends Going Section
                        if !event.attending.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Friends Going")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(Array(event.attending.prefix(4)), id: \.self) { friendId in
                                            VStack(spacing: 8) {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 60, height: 60)
                                                    .overlay(
                                                        Text(String(friendId.prefix(1).uppercased()))
                                                            .font(.system(size: 24, weight: .semibold))
                                                            .foregroundColor(.white)
                                                    )
                                                
                                                Text(friendId)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            
            // Bottom Action Buttons
            VStack(spacing: 12) {
                Spacer()
                
                // RSVP / "I'm Going" Button
                Button(action: {
                    if !isFromOtherUniversity {
                        toggleRSVP()
                    }
                }) {
                    Text(buttonText)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(isFromOtherUniversity ? Color.gray.opacity(0.2) : (hasRSVPd ? Color.getActiveRed : Color.gray.opacity(0.3)))
                        .cornerRadius(12)
                }
                .disabled(isFromOtherUniversity)
                
                // "I'm Here!" Button - Only show 1 hour prior to event
                if shouldShowImHereButton() {
                    Button(action: {
                        if !isFromOtherUniversity {
                            isHere = true
                            showHerePopup = true
                        }
                    }) {
                        Text("I'm Here!")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(isHere ? Color.gray.opacity(0.5) : Color.green)
                            .cornerRadius(12)
                    }
                    .disabled(isFromOtherUniversity || isHere)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            
            // Pop-up overlay
            if showHerePopup {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showHerePopup = false
                        }
                    
                    VStack(spacing: 20) {
                        // Close button
                        HStack {
                            Spacer()
                            Button(action: {
                                showHerePopup = false
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        // Checkmark icon
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(Color.gray.opacity(0.6))
                        }
                        
                        // Message
                        Text("Time to Get Active!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                            .frame(height: 20)
                    }
                    .padding(30)
                    .frame(width: 280)
                    .background(Color.white)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                }
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let userId = authManager.currentUser?.id {
                isLiked = event.likedBy.contains(userId)
                // Check if user has RSVP'd
                hasRSVPd = event.rsvpBy.contains(userId)
                isGoing = event.attending.contains(userId)
            }
            // Load images asynchronously
            loadImagesAsync()
        }
    }
    
    private func toggleLike() {
        guard let userId = authManager.currentUser?.id else { return }
        
        // Check current state before toggling
        let wasLiked = isLiked
        
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
        
        isLiked.toggle()
    }
    
    private func toggleRSVP() {
        guard let userId = authManager.currentUser?.id else { return }
        
        if let index = eventManager.events.firstIndex(where: { $0.id == event.id }) {
            if hasRSVPd {
                // User has RSVP'd, remove RSVP
                eventManager.events[index].rsvpBy.removeAll { $0 == userId }
                eventManager.events[index].attending.removeAll { $0 == userId }
                hasRSVPd = false
                isGoing = false
                
                // Cancel notifications
                NotificationManager.shared.cancelNotifications(for: event.id, userId: userId)
                
                // Remove from favorites
                if var user = authManager.currentUser {
                    user.favoriteEventIds.removeAll { $0 == event.id }
                    authManager.currentUser = user
                }
            } else {
                // User is RSVP'ing - add to rsvpBy and attending
                if !eventManager.events[index].rsvpBy.contains(userId) {
                    eventManager.events[index].rsvpBy.append(userId)
                }
                if !eventManager.events[index].attending.contains(userId) {
                    eventManager.events[index].attending.append(userId)
                }
                hasRSVPd = true
                isGoing = true
                
                // Schedule notifications with user's preference
                let advanceMinutes = authManager.currentUser?.notificationAdvanceMinutes ?? 30
                NotificationManager.shared.scheduleNotification(for: eventManager.events[index], userId: userId, advanceMinutes: advanceMinutes)
                
                // Add to favorites
                if var user = authManager.currentUser {
                    if !user.favoriteEventIds.contains(event.id) {
                        user.favoriteEventIds.append(event.id)
                    }
                    authManager.currentUser = user
                }
            }
            
            // Update favorites list
            eventManager.updateFavoriteEvents(userId: userId)
        }
    }
    
    private var buttonText: String {
        if isFromOtherUniversity {
            return "Unable to RSVP"
        } else if hasRSVPd {
            return "I'm Going"
        } else {
            return "RSVP"
        }
    }
    
    private func shouldShowImHereButton() -> Bool {
        // Only show if event is from user's university
        if isFromOtherUniversity {
            return false
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Combine event date and start time
        let eventStartDate = combineDateAndTime(event.date, timeString: event.startTime)
        
        // Combine event date and end time
        let eventEndDate = combineDateAndTime(event.date, timeString: event.endTime)
        
        // Calculate 1 hour before event start
        guard let oneHourBefore = calendar.date(byAdding: .hour, value: -1, to: eventStartDate) else {
            return false
        }
        
        // Show button if current time is between 1 hour before event start and event end time
        return now >= oneHourBefore && now <= eventEndDate
    }
    
    private func combineDateAndTime(_ date: Date, timeString: String) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Parse time string (e.g., "3:00 PM")
        let timeComponents = parseTimeString(timeString)
        
        var components = DateComponents()
        components.year = dateComponents.year
        components.month = dateComponents.month
        components.day = dateComponents.day
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute
        
        return calendar.date(from: components) ?? date
    }
    
    private func parseTimeString(_ timeString: String) -> (hour: Int, minute: Int) {
        let trimmed = timeString.trimmingCharacters(in: .whitespaces)
        let isPM = trimmed.uppercased().contains("PM")
        
        let timePart = trimmed.replacingOccurrences(of: "AM", with: "")
            .replacingOccurrences(of: "PM", with: "")
            .replacingOccurrences(of: "am", with: "")
            .replacingOccurrences(of: "pm", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        let components = timePart.split(separator: ":")
        guard components.count >= 1 else { return (12, 0) }
        
        var hour = Int(components[0]) ?? 12
        let minute = components.count > 1 ? Int(components[1]) ?? 0 : 0
        
        if isPM && hour != 12 {
            hour += 12
        } else if !isPM && hour == 12 {
            hour = 0
        }
        
        return (hour, minute)
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
    
    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    private func loadImagesAsync() {
        guard let customImages = event.customImages, !customImages.isEmpty else { return }
        
        Task {
            var images: [String: UIImage] = [:]
            
            for imageName in customImages {
                if let image = await loadImageFromDocumentsAsync(fileName: imageName) {
                    images[imageName] = image
                }
            }
            
            await MainActor.run {
                self.loadedImages = images
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
                    print("Error loading image: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        EventDetailView(
            event: Event(
                title: "HBCU Tech on the Yard",
                description: "Innovative tech showcase featuring HBCU students and alumni. Explore cutting-edge projects, network with tech professionals, and discover opportunities in the tech industry.",
                date: Date(),
                startTime: "3:00 PM",
                endTime: "7:00 PM",
                location: "Campus Yard - Tech Pavilion",
                category: .technology,
                tags: ["Technology", "Career", "Innovation", "HBCU"],
                backgroundColor: "blue",
                iconName: "graduationcap.fill",
                createdBy: "HBCU Tech Alliance",
                attending: ["friend1", "friend2", "friend3", "friend4"]
            ),
            eventManager: EventManager()
        )
        .environmentObject(AuthenticationManager())
    }
}

