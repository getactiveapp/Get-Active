import SwiftUI
import FirebaseFirestore

struct DataDashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = DataDashboardViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .getActiveRed))
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Stats Header
                            statsHeader
                            
                            // Users Section
                            usersSection
                            
                            // Posts/Events Section
                            postsSection
                            
                            // Messages Section
                            messagesSection
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.vertical, 20)
                    }
                }
            }
            .navigationTitle("Data Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.refreshData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                viewModel.setupListeners()
            }
            .onDisappear {
                viewModel.removeListeners()
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        VStack(spacing: 16) {
            Text("Real-Time Data")
                .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                DashboardStatCard(
                    title: "Users",
                    count: viewModel.users.count,
                    icon: "person.3.fill",
                    color: .blue
                )
                
                DashboardStatCard(
                    title: "Posts",
                    count: viewModel.posts.count,
                    icon: "calendar.badge.plus",
                    color: .getActiveRed
                )
                
                DashboardStatCard(
                    title: "Messages",
                    count: viewModel.totalMessages,
                    icon: "message.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Users Section
    
    private var usersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Users (\(viewModel.users.count))")
                    .font(.system(size: DeviceSize.bodyFontSize, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isLoadingUsers {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .getActiveRed))
                        .scaleEffect(0.8)
                }
            }
            
            if viewModel.users.isEmpty {
                EmptyStateView(
                    icon: "person.fill",
                    message: "No users found"
                )
            } else {
                ForEach(viewModel.users.prefix(10)) { user in
                    UserRow(user: user)
                }
                
                if viewModel.users.count > 10 {
                    Text("... and \(viewModel.users.count - 10) more")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Posts Section
    
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Posts/Events (\(viewModel.posts.count))")
                    .font(.system(size: DeviceSize.bodyFontSize, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isLoadingPosts {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .getActiveRed))
                        .scaleEffect(0.8)
                }
            }
            
            if viewModel.posts.isEmpty {
                EmptyStateView(
                    icon: "calendar",
                    message: "No posts found"
                )
            } else {
                ForEach(viewModel.posts.prefix(10)) { post in
                    PostRow(post: post)
                }
                
                if viewModel.posts.count > 10 {
                    Text("... and \(viewModel.posts.count - 10) more")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Messages Section
    
    private var messagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Conversations (\(viewModel.conversations.count))")
                    .font(.system(size: DeviceSize.bodyFontSize, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isLoadingMessages {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .getActiveRed))
                        .scaleEffect(0.8)
                }
            }
            
            if viewModel.conversations.isEmpty {
                EmptyStateView(
                    icon: "message",
                    message: "No conversations found"
                )
            } else {
                ForEach(viewModel.conversations.prefix(10)) { conversation in
                    DashboardConversationRow(conversation: conversation)
                }
                
                if viewModel.conversations.count > 10 {
                    Text("... and \(viewModel.conversations.count - 10) more")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - View Model

class DataDashboardViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var posts: [Event] = []
    @Published var conversations: [ConversationData] = []
    @Published var isLoading = true
    @Published var isLoadingUsers = false
    @Published var isLoadingPosts = false
    @Published var isLoadingMessages = false
    
    private let db = Firestore.firestore()
    private var usersListener: ListenerRegistration?
    private var postsListener: ListenerRegistration?
    private var conversationsListener: ListenerRegistration?
    
    var totalMessages: Int {
        conversations.reduce(0) { $0 + $1.messageCount }
    }
    
    func setupListeners() {
        setupUsersListener()
        setupPostsListener()
        setupConversationsListener()
    }
    
    func removeListeners() {
        usersListener?.remove()
        postsListener?.remove()
        conversationsListener?.remove()
        usersListener = nil
        postsListener = nil
        conversationsListener = nil
    }
    
    func refreshData() {
        // Re-setup listeners to refresh data
        removeListeners()
        setupListeners()
    }
    
    // MARK: - Users Listener
    
    private func setupUsersListener() {
        isLoadingUsers = true
        
        usersListener = db.collection("users")
            .order(by: "username")
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoadingUsers = false
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Error listening to users: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.users = []
                        return
                    }
                    
                    let loadedUsers = documents.compactMap { doc -> User? in
                        let data = doc.data()
                        return FirebaseService.shared.convertToAppUser(uid: doc.documentID, data: data)
                    }
                    
                    self?.users = loadedUsers
                    print("✅ Loaded \(loadedUsers.count) users")
                }
            }
    }
    
    // MARK: - Posts/Events Listener
    
    private func setupPostsListener() {
        isLoadingPosts = true
        
        postsListener = db.collection("events")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoadingPosts = false
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Error listening to posts: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.posts = []
                        return
                    }
                    
                    let loadedPosts = documents.compactMap { doc -> Event? in
                        let data = doc.data()
                        return FirebaseService.shared.convertToEvent(docID: doc.documentID, data: data)
                    }
                    
                    self?.posts = loadedPosts
                    print("✅ Loaded \(loadedPosts.count) posts")
                }
            }
    }
    
    // MARK: - Conversations/Messages Listener
    
    private func setupConversationsListener() {
        isLoadingMessages = true
        
        conversationsListener = db.collection("conversations")
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                DispatchQueue.main.async {
                    self?.isLoadingMessages = false
                    self?.isLoading = false
                    
                    if let error = error {
                        print("❌ Error listening to conversations: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.conversations = []
                        return
                    }
                    
                    let loadedConversations = documents.compactMap { doc -> ConversationData? in
                        let data = doc.data()
                        return ConversationData(
                            id: doc.documentID,
                            data: data
                        )
                    }
                    
                    self?.conversations = loadedConversations
                    print("✅ Loaded \(loadedConversations.count) conversations")
                    
                    // Load message counts for each conversation
                    self?.loadMessageCounts()
                }
            }
    }
    
    private func loadMessageCounts() {
        for index in conversations.indices {
            let conversationId = conversations[index].id
            db.collection("conversations")
                .document(conversationId)
                .collection("messages")
                .getDocuments { [weak self] snapshot, _ in
                    DispatchQueue.main.async {
                        let count = snapshot?.documents.count ?? 0
                        if index < self?.conversations.count ?? 0 {
                            self?.conversations[index].messageCount = count
                        }
                    }
                }
        }
    }
}

// MARK: - Supporting Views

struct DashboardStatCard: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct UserRow: View {
    let user: User
    @State private var isOnline = false
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(user.name.prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                if isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.getActiveBlack, lineWidth: 2)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(user.accountType.rawValue)
                .font(.system(size: 12))
                .foregroundColor(.getActiveRed)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.getActiveRed.opacity(0.2))
                .cornerRadius(8)
        }
        .padding(.vertical, 8)
        .onAppear {
            // Observe online status from Realtime Database
            RealtimeDatabaseService.shared.observeUserStatus(userId: user.id) { online, _ in
                isOnline = online
            }
        }
    }
}

struct PostRow: View {
    let post: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(post.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(post.category.rawValue)
                    .font(.system(size: 12))
                    .foregroundColor(.getActiveRed)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.getActiveRed.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Text(post.description)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Label("\(post.attending.count)", systemImage: "person.2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Label("\(post.likedBy.count)", systemImage: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(post.date, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}

struct DashboardConversationRow: View {
    let conversation: ConversationData
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "message.fill")
                .font(.system(size: 20))
                .foregroundColor(.getActiveRed)
                .frame(width: 40, height: 40)
                .background(Color.getActiveRed.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Conversation")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(conversation.participantsText)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.8))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(conversation.messageCount)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.getActiveRed)
                
                Text("msgs")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}

// MARK: - Conversation Data Model

struct ConversationData: Identifiable {
    let id: String
    let participants: [String]
    let lastMessage: String?
    let lastMessageTimestamp: Date?
    var messageCount: Int = 0
    
    var participantsText: String {
        participants.joined(separator: ", ")
    }
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.participants = data["participants"] as? [String] ?? []
        self.lastMessage = data["lastMessage"] as? String
        if let timestamp = data["lastMessageTimestamp"] as? Timestamp {
            self.lastMessageTimestamp = timestamp.dateValue()
        } else {
            self.lastMessageTimestamp = nil
        }
        self.messageCount = 0
    }
}

