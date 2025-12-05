import SwiftUI
import UIKit

struct EventDetailView: View {
    let event: Event
    @EnvironmentObject var authManager: AuthenticationManager
    @ObservedObject var eventManager: EventManager
    @Environment(\.dismiss) var dismiss
    @State private var isLiked = false
    @State private var isGoing = false
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
            
            // Bottom "Going" Button
            VStack {
                Spacer()
                Button(action: {
                    if !isFromOtherUniversity {
                        toggleGoing()
                    }
                }) {
                    Text(isFromOtherUniversity ? "Unable to say going" : (isGoing ? "I'm going" : "Going"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 55)
                        .background(isFromOtherUniversity ? Color.gray.opacity(0.2) : (isGoing ? Color.getActiveRed : Color.gray.opacity(0.3)))
                        .cornerRadius(12)
                }
                .disabled(isFromOtherUniversity)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Event Details")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .onAppear {
            if let userId = authManager.currentUser?.id {
                isLiked = event.likedBy.contains(userId)
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
    
    private func toggleGoing() {
        guard let userId = authManager.currentUser?.id else { return }
        
        if let index = eventManager.events.firstIndex(where: { $0.id == event.id }) {
            if eventManager.events[index].attending.contains(userId) {
                eventManager.events[index].attending.removeAll { $0 == userId }
                isGoing = false
            } else {
                if !eventManager.events[index].attending.contains(userId) {
                    eventManager.events[index].attending.append(userId)
                }
                isGoing = true
            }
            // Note: updateFavoriteEvents is called but won't affect favorites since favorites only include liked events, not attending events
            eventManager.updateFavoriteEvents(userId: userId)
        }
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

