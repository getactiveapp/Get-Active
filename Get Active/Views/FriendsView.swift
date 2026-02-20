import SwiftUI

enum FriendsTab: String, CaseIterable {
    case friends = "Friends"
    case requests = "Requests"
    case suggestions = "Suggestions"
}

struct FriendsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedTab: FriendsTab = .friends
    @State private var showingFilter = false
    @State private var showOnlineOnly = true
    @State private var selectedFriend: Friend?
    @State private var showingFriendProfile = false
    @State private var showingChat = false
    @State private var allFriends: [Friend] = []
    @State private var friendRequests: [Friend] = []
    @State private var suggestions: [Friend] = []
    @State private var isLoading = false
    
    // Load real friends from Firebase
    private func loadFriends() {
        guard let userId = authManager.currentUser?.id else {
            allFriends = []
            friendRequests = []
            suggestions = []
            return
        }
        
        isLoading = true
        
        // Load user's friends from Firestore
        FirebaseService.shared.getUser(uid: userId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let user):
                    // Load friend details
                    self.loadFriendDetails(friendIds: user.friends)
                    // Load friend requests (would need a separate collection or field)
                    self.loadFriendRequests(userId: userId)
                    // Load suggestions (would need algorithm or separate query)
                    self.loadSuggestions(userId: userId)
                case .failure(let error):
                    print("Error loading friends: \(error.localizedDescription)")
                    self.allFriends = []
                    self.friendRequests = []
                    self.suggestions = []
                }
            }
        }
    }
    
    private func loadFriendDetails(friendIds: [String]) {
        // Load details for each friend
        var loadedFriends: [Friend] = []
        let group = DispatchGroup()
        
        for friendId in friendIds {
            group.enter()
            FirebaseService.shared.getUser(uid: friendId) { result in
                defer { group.leave() }
                switch result {
                case .success(let user):
                    // Check online status from Realtime Database
                    RealtimeDatabaseService.shared.observeUserStatus(userId: friendId) { isOnline, _ in
                        DispatchQueue.main.async {
                            let friend = Friend(
                                id: user.id,
                                name: user.name,
                                university: user.university,
                                mutualFriends: self.calculateMutualFriends(currentUserId: self.authManager.currentUser?.id ?? "", friendId: friendId),
                                isOnline: isOnline
                            )
                            loadedFriends.append(friend)
                        }
                    }
                case .failure:
                    break
                }
            }
        }
        
        group.notify(queue: .main) {
            self.allFriends = loadedFriends
        }
    }
    
    private func loadFriendRequests(userId: String) {
        // Load friend requests from Firestore
        // This would require a friendRequests collection or field
        // For now, set to empty - implement when friend request system is ready
        friendRequests = []
    }
    
    private func loadSuggestions(userId: String) {
        // Load friend suggestions from Firestore
        // This would require an algorithm or separate query
        // For now, set to empty - implement when suggestion system is ready
        suggestions = []
    }
    
    private func calculateMutualFriends(currentUserId: String, friendId: String) -> Int {
        // Calculate mutual friends from Firestore
        // For now, return 0 - implement when friend system is ready
        return 0
    }
    
    private var displayedFriends: [Friend] {
        let source: [Friend]
        switch selectedTab {
        case .friends:
            source = allFriends
        case .requests:
            source = friendRequests
        case .suggestions:
            source = suggestions
        }
        
        var filtered = source
        
        // Filter by online status if enabled
        if showOnlineOnly && selectedTab == .friends {
            filtered = filtered.filter { $0.isOnline }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { friend in
                friend.name.localizedCaseInsensitiveContains(searchText) ||
                friend.university.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
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
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text("Friends")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.clear)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 15)
                
                // Search Bar
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        TextField("Search friends...", text: $searchText)
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    
                    Button(action: {
                        showingFilter = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.getActiveRed)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
                
                // Filter Message
                if showOnlineOnly && selectedTab == .friends {
                    HStack {
                        Text("Showing online friends only")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.getActiveRed)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 15)
                }
                
                // Tabs
                HStack(spacing: 6) {
                    ForEach(FriendsTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            HStack(spacing: 2) {
                                Text(tab.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Text("(\(getCount(for: tab)))")
                                    .font(.system(size: 14, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? Color.getActiveRed : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
                
                // Friends List
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(displayedFriends) { friend in
                            FriendRowCard(
                                friend: friend,
                                tabType: selectedTab, // Pass the tab type to determine button layout
                                onTap: {
                                    selectedFriend = friend
                                    showingFriendProfile = true
                                },
                                onMessageTap: {
                                    selectedFriend = friend
                                    showingChat = true
                                },
                                onAccept: {
                                    // Accept friend request - send notification to that person
                                    if authManager.currentUser != nil {
                                        // Send notification to the person whose request we accepted
                                        NotificationManager.shared.sendFriendAcceptNotification(
                                            fromUserName: authManager.currentUser?.name ?? "Someone",
                                            toUserId: friend.id
                                        )
                                    }
                                },
                                onDecline: {
                                    // Decline friend request - remove from requests
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadFriends()
        }
        .sheet(item: $selectedFriend) { friend in
            NavigationView {
                FriendProfileView(friendName: friend.name, friendId: friend.id, eventManager: EventManager())
                    .environmentObject(authManager)
            }
        }
        .sheet(isPresented: $showingChat) {
            if let friend = selectedFriend {
                NavigationView {
                    ChatView(conversationId: nil, friendId: friend.id, friendName: friend.name)
                        .environmentObject(authManager)
                }
            }
        }
        .confirmationDialog("Filter Options", isPresented: $showingFilter, titleVisibility: .visible) {
            Button(showOnlineOnly ? "Show All Friends" : "Show Online Only") {
                showOnlineOnly.toggle()
            }
        }
    }
    
    private func getCount(for tab: FriendsTab) -> Int {
        switch tab {
        case .friends:
            return allFriends.count
        case .requests:
            return friendRequests.count
        case .suggestions:
            return suggestions.count
        }
    }
    
    // Removed sendFriendRequestNotificationsIfNeeded() - notifications handled by Firebase
}

struct Friend: Identifiable {
    let id: String
    let name: String
    let university: String
    let mutualFriends: Int
    let isOnline: Bool
}

struct FriendRowCard: View {
    let friend: Friend
    let tabType: FriendsTab // The current tab to determine button layout
    var onTap: () -> Void
    var onMessageTap: () -> Void
    var onAccept: () -> Void
    var onDecline: () -> Void
    @State private var showingMenu = false
    
    private var isFriend: Bool {
        tabType == .friends
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Profile Picture
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(friend.name.prefix(1)))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                // Online indicator
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(friend.university)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                Text("\(friend.mutualFriends) mutual friend\(friend.mutualFriends == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.getActiveRed)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if tabType == .friends {
                    // Friends tab - show message and menu buttons
                    Button(action: {
                        // Navigate to direct chat with this friend
                        onMessageTap()
                    }) {
                        Image(systemName: "message")
                            .font(.system(size: 18))
                            .foregroundColor(.getActiveRed)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.getActiveRed, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onMessageTap()
                    })
                    
                    Button(action: {
                        showingMenu = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18))
                            .foregroundColor(.getActiveRed)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(Color.getActiveRed, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Requests and Suggestions tabs - show Accept and Decline buttons
                    Button(action: {
                        onAccept()
                    }) {
                        Text("Accept")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.getActiveRed)
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onAccept()
                    })
                    
                    Button(action: {
                        onDecline()
                    }) {
                        Text("Decline")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.getActiveRed)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.getActiveRed, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .highPriorityGesture(TapGesture().onEnded {
                        onDecline()
                    })
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .confirmationDialog("Options", isPresented: $showingMenu, titleVisibility: .visible) {
            Button("Unfriend", role: .destructive) {
                // Unfriend action
            }
            Button("Block", role: .destructive) {
                // Block action
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

#Preview {
    FriendsView()
        .environmentObject(AuthenticationManager())
}
