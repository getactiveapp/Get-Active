import SwiftUI

struct UserSearchView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isLoading = false
    @State private var searchError: String?
    @State private var selectedUser: User?
    @State private var showingUserProfile = false
    
    private let firebaseService = FirebaseService.shared
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text("Search Users")
                        .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.clear)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 6)
                
                // Search Bar
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .font(.system(size: DeviceSize.iconSize))
                        
                        TextField("Search by username or name...", text: $searchText)
                            .font(.system(size: DeviceSize.bodyFontSize))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .onChange(of: searchText) { _, newValue in
                                performSearch(query: newValue)
                            }
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                                searchResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: DeviceSize.iconSize))
                            }
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding * 0.6)
                    .padding(.vertical, DeviceSize.searchBarHeight * 0.3)
                    .frame(height: DeviceSize.searchBarHeight)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 12)
                
                // Loading Indicator
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(.getActiveRed)
                        Text("Searching...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        Spacer()
                    }
                } else if searchText.isEmpty {
                    // Empty State
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("Search for users")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Enter a username or name to search")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else if searchResults.isEmpty {
                    // No Results
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "person.slash")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("No users found")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Try a different search term")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    // Results List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(searchResults) { user in
                                UserSearchResultRow(user: user) {
                                    selectedUser = user
                                    showingUserProfile = true
                                }
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                // Error Message
                if let error = searchError {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.getActiveRed)
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, 8)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingUserProfile) {
            if let user = selectedUser {
                NavigationView {
                    FriendProfileView(friendName: user.name, friendId: user.id, eventManager: EventManager())
                        .environmentObject(authManager)
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            searchError = nil
            return
        }
        
        guard query.count >= 2 else {
            // Don't search until at least 2 characters
            return
        }
        
        isLoading = true
        searchError = nil
        
        // Debounce search - wait 0.5 seconds after user stops typing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.searchText == query else {
                // User has typed more, ignore this result
                return
            }
            
            firebaseService.searchUsers(query: query) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let users):
                        self.searchResults = users
                    case .failure(let error):
                        self.searchError = "Search failed: \(error.localizedDescription)"
                        self.searchResults = []
                    }
                }
            }
        }
    }
}

struct UserSearchResultRow: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: 15) {
                // Profile Picture
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Text(String(user.name.prefix(1)))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    if !user.university.isEmpty {
                        Text(user.university)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    UserSearchView()
        .environmentObject(AuthenticationManager())
}

