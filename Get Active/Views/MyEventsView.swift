import SwiftUI

struct MyEventsView: View {
    @ObservedObject var eventManager: EventManager
    @ObservedObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    var myEvents: [Event] {
        guard let userId = authManager.currentUser?.id else { return [] }
        return eventManager.events.filter { $0.createdBy == userId }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                if myEvents.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No Events Yet")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Create your first event to get started")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                } else {
                    ScrollView {
                            VStack(spacing: 15) {
                            ForEach(myEvents) { event in
                                MyEventCard(event: event, eventManager: eventManager)
                                    .environmentObject(authManager)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("My Events")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

struct MyEventCard: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("\(formatDate(event.date)) • \(event.startTime)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(event.location)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text("\(event.likedBy.count)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.getActiveRed)
                
                Text("Likes")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 18))
                    .foregroundColor(.getActiveRed)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete \"\(event.title)\"? This action cannot be undone.")
        }
    }
    
    private func deleteEvent() {
        // Remove event from eventManager
        eventManager.events.removeAll { $0.id == event.id }
        
        // Delete associated image files
        if let customImages = event.customImages {
            let fileManager = FileManager.default
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            for imageName in customImages {
                let filePath = documentsPath.appendingPathComponent(imageName)
                try? fileManager.removeItem(at: filePath)
            }
        }
        
        // Cancel any pending notifications for this event
        if let userId = authManager.currentUser?.id {
            NotificationManager.shared.cancelNotifications(for: event.id, userId: userId)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yyyy"
        return formatter.string(from: date)
    }
}

