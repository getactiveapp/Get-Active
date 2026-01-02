import SwiftUI

struct FriendProfileView: View {
    let friendName: String
    let friendId: String
    @ObservedObject var eventManager: EventManager
    @StateObject private var friendActivityManager = FriendActivityManager()
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var showingChat = false
    @State private var showingUnfriendAlert = false
    
    // Check if this person is in the user's friends list
    private var isFriend: Bool {
        authManager.currentUser?.friends.contains(friendId) == true
    }
    
    // Friend data - in a real app, this would come from a user database
    private var friendData: FriendData {
        getFriendData(for: friendId)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Header with Red Background
                        ZStack {
                            Color.getActiveRed
                                .frame(height: 400)
                            
                            VStack(spacing: 12) {
                                // Profile Image
                                ZStack(alignment: .bottomTrailing) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Text(String(friendName.prefix(1)))
                                                .font(.system(size: 50, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    // Online status indicator
                                    if friendData.isOnline {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.getActiveRed, lineWidth: 2)
                                            )
                                    }
                                }
                                
                                // Online status text
                                if friendData.isOnline {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("Online now")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                // Name
                                Text(friendName)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                
                                // University & Grade
                                HStack(spacing: 4) {
                                    Text(friendData.university)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                    Text("•")
                                        .foregroundColor(.white)
                                    Text(friendData.year)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                                
                                // Bio
                                Text(friendData.bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 30)
                                    .padding(.top, 8)
                                
                                // Joined date
                                Text("Joined \(friendData.joinedDate)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.top, 8)
                            }
                            .padding(.top, 60)
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            // Only show message button if they're a friend
                            if isFriend {
                                Button(action: {
                                    showingChat = true
                                }) {
                                    HStack {
                                        Image(systemName: "message.fill")
                                            .font(.system(size: 16))
                                        Text("Message")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.getActiveRed)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: {
                                showingUnfriendAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "person.2.slash")
                                        .font(.system(size: 16))
                                    Text("Unfriend")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Statistics Cards
                        HStack(spacing: 12) {
                            // Mutual Friends Card
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.getActiveRed)
                                
                                Text("\(getMutualFriendsCount())")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Mutual Friends")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            
                            // Events Attending Card
                            VStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 24))
                                    .foregroundColor(.getActiveRed)
                                
                                Text("\(getEventsCount())")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Events Attending")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Mutual Friends Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mutual Friends (\(getMutualFriendsCount()))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(getMutualFriends()) { friend in
                                        VStack(spacing: 8) {
                                            ZStack(alignment: .bottomTrailing) {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 60, height: 60)
                                                    .overlay(
                                                        Text(String(friend.name.prefix(1)))
                                                            .font(.system(size: 24, weight: .semibold))
                                                            .foregroundColor(.white)
                                                    )
                                                
                                                if friend.isOnline {
                                                    Circle()
                                                        .fill(Color.green)
                                                        .frame(width: 14, height: 14)
                                                        .overlay(
                                                            Circle()
                                                                .stroke(Color.getActiveBlack, lineWidth: 2)
                                                        )
                                                }
                                            }
                                            
                                            Text(friend.name)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 25)
                        
                        // Events Attending Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Events Attending (\(getEventsCount()))")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            let attendingEvents = eventManager.events.filter { $0.attending.contains(friendId) }
                            
                            if attendingEvents.isEmpty {
                                VStack(spacing: 10) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No events")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(attendingEvents.prefix(5)) { event in
                                        EventRow(event: event, eventManager: eventManager)
                                            .environmentObject(authManager)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(friendName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingChat) {
                NavigationView {
                    ChatView(conversationId: nil, friendId: friendId, friendName: friendName)
                        .environmentObject(authManager)
                }
            }
            .alert("Unfriend \(friendName)?", isPresented: $showingUnfriendAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Unfriend", role: .destructive) {
                    unfriendUser()
                }
            } message: {
                Text("Are you sure you want to remove \(friendName) from your friends list?")
            }
        }
    }
    
    private func getEventsCount() -> Int {
        return eventManager.events.filter { $0.attending.contains(friendId) }.count
    }
    
    private func getMutualFriendsCount() -> Int {
        guard authManager.currentUser != nil else { return 0 }
        // In a real app, this would check the friend's friends list
        // For now, we'll return sample data
        return 3
    }
    
    private func getMutualFriends() -> [MutualFriend] {
        // Sample mutual friends - in a real app, this would calculate from both users' friend lists
        return [
            MutualFriend(id: "1", name: "Isabella", isOnline: true),
            MutualFriend(id: "2", name: "Stacy", isOnline: false),
            MutualFriend(id: "3", name: "Dj", isOnline: true)
        ]
    }
    
    private func getFriendData(for friendId: String) -> FriendData {
        // Sample friend data - in a real app, this would fetch from a user database
        switch friendId {
        case "friend1", "ray":
            return FriendData(
                university: "Central State University",
                year: "Junior • 11th Grade",
                bio: "Music lover and event organizer. Always down for a good time!",
                joinedDate: "2 years ago",
                isOnline: true
            )
        default:
            return FriendData(
                university: "Central State University",
                year: "Sophomore",
                bio: "Event enthusiast and campus leader.",
                joinedDate: "1 year ago",
                isOnline: false
            )
        }
    }
    
    private func unfriendUser() {
        // Remove friend from current user's friends list
        if var user = authManager.currentUser {
            user.friends.removeAll { $0 == friendId }
            authManager.updateUser(user)
            dismiss()
        }
    }
}

struct FriendData {
    let university: String
    let year: String
    let bio: String
    let joinedDate: String
    let isOnline: Bool
}

struct MutualFriend: Identifiable {
    let id: String
    let name: String
    let isOnline: Bool
}

struct EventRow: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedEvent: Event?
    
    var body: some View {
        Button(action: {
            selectedEvent = event
        }) {
            HStack(spacing: 12) {
                // Event icon/color
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColorForEvent(event))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: event.iconName ?? "calendar")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(formatDate(event.date))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .sheet(item: $selectedEvent) { event in
            NavigationView {
                EventDetailView(event: event, eventManager: eventManager)
                    .environmentObject(authManager)
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
        default: return Color.getActiveRed
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}


