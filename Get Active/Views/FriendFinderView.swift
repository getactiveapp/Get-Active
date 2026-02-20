import SwiftUI

struct FriendFinderView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentProfileIndex = 0
    @State private var showingProfileDetail = false
    @State private var selectedProfile: DiscoverableProfile?
    @State private var allProfiles: [DiscoverableProfile] = []
    @State private var filteredProfiles: [DiscoverableProfile] = []
    @State private var profileHistory: [Int] = [] // Track profile indices we've seen
    @State private var dragOffset: CGSize = .zero
    @State private var rotationAngle: Double = 0
    @State private var showingFilter = false
    @State private var selectedInterests: Set<String> = []
    @State private var selectedMajors: Set<String> = []
    @State private var selectedYears: Set<String> = []
    @State private var availableInterests: [String] = []
    @State private var availableMajors: [String] = []
    @State private var availableYears: [String] = []
    
    // Computed property to get current profiles list
    private var profiles: [DiscoverableProfile] {
        filteredProfiles.isEmpty ? allProfiles : filteredProfiles
    }
    
    // Computed property to get total active filter count
    private var activeFilterCount: Int {
        selectedInterests.count + selectedMajors.count + selectedYears.count
    }
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Discover")
                        .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Filter Button
                    Button(action: {
                        showingFilter = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: activeFilterCount == 0 ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                .font(.system(size: DeviceSize.iconSize))
                            if activeFilterCount > 0 {
                                Text("\(activeFilterCount)")
                                    .font(.system(size: DeviceSize.captionFontSize, weight: .semibold))
                            }
                        }
                        .foregroundColor(activeFilterCount == 0 ? .white : .getActiveRed)
                        .padding(.horizontal, DeviceSize.isPad ? 12 : 10)
                        .padding(.vertical, DeviceSize.isPad ? 8 : 6)
                        .background(activeFilterCount == 0 ? Color.gray.opacity(0.2) : Color.getActiveRed.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.top, DeviceSize.isPad ? 20 : 10)
                .padding(.bottom, DeviceSize.isPad ? 20 : 10)
                
                // Profile Card Area
                if currentProfileIndex < profiles.count {
                    ZStack {
                        // Background cards (stacked effect)
                        if currentProfileIndex + 1 < profiles.count {
                            ProfileCard(profile: profiles[currentProfileIndex + 1], onAddFriend: nil)
                            .environmentObject(authManager)
                            .scaleEffect(0.95)
                            .opacity(0.7)
                            .offset(y: 20)
                        }
                        
                        if currentProfileIndex + 2 < profiles.count {
                            ProfileCard(profile: profiles[currentProfileIndex + 2], onAddFriend: nil)
                            .environmentObject(authManager)
                            .scaleEffect(0.9)
                            .opacity(0.5)
                            .offset(y: 40)
                        }
                        
                        // Current card
                        ProfileCard(profile: profiles[currentProfileIndex], onAddFriend: {
                            // Add current index to history before moving
                            if currentProfileIndex < profiles.count {
                                profileHistory.append(currentProfileIndex)
                            }
                            
                            // Animate card off screen to the right
                            withAnimation(.spring()) {
                                dragOffset = CGSize(width: 1000, height: 0)
                                rotationAngle = 30
                            }
                            
                            // Move to next profile after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                moveToNextProfile()
                            }
                        })
                        .id(profiles[currentProfileIndex].id)
                        .environmentObject(authManager)
                        .offset(dragOffset)
                        .rotationEffect(.degrees(rotationAngle))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation
                                    rotationAngle = Double(value.translation.width / 20)
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 100
                                    if abs(value.translation.width) > threshold {
                                        // Swipe left (reject) or right (like)
                                        if value.translation.width > 0 {
                                            // Like
                                            likeProfile()
                                        } else {
                                            // Reject
                                            rejectProfile()
                                        }
                                    } else {
                                        // Snap back
                                        withAnimation(.spring()) {
                                            dragOffset = .zero
                                            rotationAngle = 0
                                        }
                                    }
                                }
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                } else {
                    // No more profiles
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No more profiles")
                            .font(.system(size: DeviceSize.titleFontSize, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Check back later for more people to discover!")
                            .font(.system(size: DeviceSize.bodyFontSize))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DeviceSize.horizontalPadding * 2)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // Action Buttons
                HStack(spacing: DeviceSize.isPad ? 40 : 30) {
                    // Reject Button
                    Button(action: {
                        rejectProfile()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: DeviceSize.isPad ? 70 : 60, height: DeviceSize.isPad ? 70 : 60)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: DeviceSize.isPad ? 28 : 24, weight: .bold))
                                    .foregroundColor(.getActiveRed)
                            )
                    }
                    
                    // Back/Undo Button
                    Button(action: {
                        goBackToPreviousProfile()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: DeviceSize.isPad ? 70 : 60, height: DeviceSize.isPad ? 70 : 60)
                            .overlay(
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: DeviceSize.isPad ? 28 : 24, weight: .bold))
                                    .foregroundColor(.blue)
                            )
                    }
                    .disabled(profileHistory.isEmpty || currentProfileIndex == 0)
                    .opacity((profileHistory.isEmpty || currentProfileIndex == 0) ? 0.5 : 1.0)
                    
                    // Like Button
                    Button(action: {
                        likeProfile()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: DeviceSize.isPad ? 70 : 60, height: DeviceSize.isPad ? 70 : 60)
                            .overlay(
                                Text("❤️")
                                    .font(.system(size: DeviceSize.isPad ? 32 : 28))
                            )
                    }
                }
                .padding(.bottom, DeviceSize.isPad ? 40 : 30)
                .padding(.top, DeviceSize.isPad ? 30 : 20)
            }
        }
        .onAppear {
            loadRealProfiles()
            extractAvailableFilters()
        }
        .sheet(isPresented: $showingProfileDetail) {
            if let profile = selectedProfile {
                NavigationView {
                    ProfileDetailSheet(profile: profile)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    showingProfileDetail = false
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                }
                .preferredColorScheme(.dark)
            }
        }
        .sheet(isPresented: $showingFilter) {
            FriendFinderFilterView(
                availableInterests: availableInterests,
                availableMajors: availableMajors,
                availableYears: availableYears,
                selectedInterests: $selectedInterests,
                selectedMajors: $selectedMajors,
                selectedYears: $selectedYears,
                onApply: {
                    applyFilters()
                }
            )
        }
    }
    
    private func likeProfile() {
        // Add current index to history before moving
        if currentProfileIndex < profiles.count {
            profileHistory.append(currentProfileIndex)
        }
        
        // Animate card off screen to the right
        withAnimation(.spring()) {
            dragOffset = CGSize(width: 1000, height: 0)
            rotationAngle = 30
        }
        
        // Move to next profile after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            moveToNextProfile()
        }
    }
    
    private func rejectProfile() {
        // Add current index to history before moving
        if currentProfileIndex < profiles.count {
            profileHistory.append(currentProfileIndex)
        }
        
        // Animate card off screen to the left
        withAnimation(.spring()) {
            dragOffset = CGSize(width: -1000, height: 0)
            rotationAngle = -30
        }
        
        // Move to next profile after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            moveToNextProfile()
        }
    }
    
    private func moveToNextProfile() {
        currentProfileIndex += 1
        dragOffset = .zero
        rotationAngle = 0
    }
    
    private func goBackToPreviousProfile() {
        guard !profileHistory.isEmpty else { return }
        
        // Get the last profile index from history
        let previousIndex = profileHistory.removeLast()
        
        // Animate back to previous profile
        withAnimation(.spring()) {
            currentProfileIndex = previousIndex
            dragOffset = .zero
            rotationAngle = 0
        }
    }
    
    private func extractAvailableFilters() {
        var interestsSet = Set<String>()
        var majorsSet = Set<String>()
        var yearsSet = Set<String>()
        
        for profile in allProfiles {
            // Extract interests
            for interest in profile.interests {
                interestsSet.insert(interest)
            }
            // Extract majors
            majorsSet.insert(profile.major)
            // Extract years
            yearsSet.insert(profile.year)
        }
        
        availableInterests = Array(interestsSet).sorted()
        availableMajors = Array(majorsSet).sorted()
        availableYears = Array(yearsSet).sorted()
    }
    
    private func applyFilters() {
        let hasFilters = !selectedInterests.isEmpty || !selectedMajors.isEmpty || !selectedYears.isEmpty
        
        if !hasFilters {
            filteredProfiles = []
        } else {
            filteredProfiles = allProfiles.filter { profile in
                // Check interests (if any selected)
                let matchesInterests = selectedInterests.isEmpty || profile.interests.contains { interest in
                    selectedInterests.contains(interest)
                }
                
                // Check major (if any selected)
                let matchesMajor = selectedMajors.isEmpty || selectedMajors.contains(profile.major)
                
                // Check year (if any selected)
                let matchesYear = selectedYears.isEmpty || selectedYears.contains(profile.year)
                
                // Profile matches if it satisfies all selected filter categories
                return matchesInterests && matchesMajor && matchesYear
            }
        }
        
        // Reset to first profile when filter is applied
        currentProfileIndex = 0
        profileHistory = []
        dragOffset = .zero
        rotationAngle = 0
    }
    
    private func loadRealProfiles() {
        // Load discoverable profiles from Firestore
        guard let currentUserId = authManager.currentUser?.id else {
            allProfiles = []
            return
        }
        
        // Query all users (can be filtered later by discoverable profile settings)
        FirebaseService.shared.searchUsers(query: "") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let users):
                    // Convert users to discoverable profiles
                    allProfiles = users.compactMap { user -> DiscoverableProfile? in
                        // Only include users who are not the current user
                        guard user.id != currentUserId else {
                            return nil
                        }
                        
                        // Use user's friendFinderDescription as bio, or fallback to bio
                        let bio = user.friendFinderDescription.isEmpty ? user.bio : user.friendFinderDescription
                        
                        // Parse interests from bio or tags (if available in future)
                        // For now, use empty interests array - can be populated from user data later
                        let interests: [String] = []
                        
                        return DiscoverableProfile(
                            name: user.name,
                            major: "", // Major not in User model yet - can be added later
                            location: user.university,
                            year: user.year,
                            bio: bio,
                            interests: interests
                        )
                    }
                case .failure(let error):
                    print("Error loading profiles: \(error.localizedDescription)")
                    allProfiles = []
                }
            }
        }
    }
}

struct ProfileCard: View {
    let profile: DiscoverableProfile
    var onAddFriend: (() -> Void)?
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var imageLoaded: UIImage?
    @State private var profileImageLoaded: UIImage?
    @State private var isFriend = false
    @State private var showingAddFriendConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Red area at top with profile image
            ZStack {
                Color.getActiveRed
                    .frame(height: DeviceSize.screenHeight * 0.4)
                
                // Profile image in the red area
                if let profileImage = profileImageLoaded {
                    Image(uiImage: profileImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: DeviceSize.screenWidth - (DeviceSize.horizontalPadding * 2), height: DeviceSize.screenHeight * 0.4)
                        .clipped()
                } else {
                    // Placeholder circle with initial
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: DeviceSize.isPad ? 150 : 120, height: DeviceSize.isPad ? 150 : 120)
                        .overlay(
                            Text(String(profile.name.prefix(1)))
                                .font(.system(size: DeviceSize.isPad ? 60 : 50, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
            }
            
            // Content area below
            ZStack(alignment: .bottom) {
                Color.getActiveBlack
                    .frame(height: DeviceSize.screenHeight * 0.25)
                
                // Dark overlay at bottom for text readability
                VStack {
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 250)
                }
                
                // Content overlay
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    
                    // Name and Add button
                    HStack {
                        Text(profile.name)
                            .font(.system(size: DeviceSize.isPad ? 32 : 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            handleAddFriend()
                        }) {
                            Circle()
                                .fill(isFriend ? Color.gray : Color.getActiveRed)
                                .frame(width: DeviceSize.isPad ? 36 : 32, height: DeviceSize.isPad ? 36 : 32)
                                .overlay(
                                    Image(systemName: isFriend ? "checkmark" : "plus")
                                        .font(.system(size: DeviceSize.isPad ? 18 : 16, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // Education
                    HStack(spacing: 8) {
                        Image(systemName: "graduationcap.fill")
                            .font(.system(size: DeviceSize.iconSize))
                            .foregroundColor(.white)
                        Text(profile.major)
                            .font(.system(size: DeviceSize.bodyFontSize))
                            .foregroundColor(.white)
                    }
                    
                    // Location
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: DeviceSize.iconSize))
                            .foregroundColor(.white)
                        Text(profile.location)
                            .font(.system(size: DeviceSize.bodyFontSize))
                            .foregroundColor(.white)
                    }
                    
                    // Interests
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(profile.interests.prefix(4), id: \.self) { interest in
                                Text(interest)
                                    .font(.system(size: DeviceSize.captionFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, DeviceSize.isPad ? 12 : 10)
                                    .padding(.vertical, DeviceSize.isPad ? 6 : 5)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                            }
                            
                            if profile.interests.count > 4 {
                                Text("+\(profile.interests.count - 4)")
                                    .font(.system(size: DeviceSize.captionFontSize, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, DeviceSize.isPad ? 12 : 10)
                                    .padding(.vertical, DeviceSize.isPad ? 6 : 5)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(.horizontal, DeviceSize.horizontalPadding)
                .padding(.bottom, DeviceSize.isPad ? 30 : 20)
            }
        }
        .frame(width: DeviceSize.screenWidth - (DeviceSize.horizontalPadding * 2), height: DeviceSize.screenHeight * 0.65)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        .onAppear {
            loadProfileImage()
            // Reset state first, then check
            isFriend = false
            showingAddFriendConfirmation = false
            checkIfFriend()
        }
        .onChange(of: profile.id) { _ in
            // Reset friend state when profile changes
            isFriend = false
            showingAddFriendConfirmation = false
            checkIfFriend()
        }
        .sheet(isPresented: $showingAddFriendConfirmation) {
            AddFriendConfirmationView(
                friendName: profile.name,
                isPresented: $showingAddFriendConfirmation,
                onDismiss: {
                    onAddFriend?()
                }
            )
        }
    }
    
    private func loadProfileImage() {
        // Load profile image if available
        if let imageName = profile.profileImageName {
            // In a real app, you'd load from URL or local storage
            Task {
                // Simulate loading - in real app, load from storage/URL
                await MainActor.run {
                    // Placeholder - you can add actual image loading here
                }
            }
        }
    }
    
    private func checkIfFriend() {
        guard let userId = authManager.currentUser?.id else { return }
        // Check if this profile is already a friend
        // For now, we'll check by ID - in a real app, you'd have a friends list
        isFriend = authManager.currentUser?.friends.contains(profile.id) ?? false
    }
    
    private func handleAddFriend() {
        guard let userId = authManager.currentUser?.id else { return }
        
        if !isFriend {
            // Add friend
            if var user = authManager.currentUser {
                if !user.friends.contains(profile.id) {
                    user.friends.append(profile.id)
                    authManager.updateUser(user)
                }
                isFriend = true
                showingAddFriendConfirmation = true
            }
        } else {
            // Remove friend
            if var user = authManager.currentUser {
                user.friends.removeAll { $0 == profile.id }
                authManager.updateUser(user)
                isFriend = false
            }
        }
    }
}

struct ProfileDetailSheet: View {
    let profile: DiscoverableProfile
    @Environment(\.dismiss) var dismiss
    @State private var profileImageLoaded: UIImage?
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Image Section (Red area)
                    ZStack {
                        Color.getActiveRed
                            .frame(height: DeviceSize.isPad ? 350 : 280)
                        
                        // Profile image
                        if let profileImage = profileImageLoaded {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width, height: DeviceSize.isPad ? 350 : 280)
                                .clipped()
                        } else {
                            // Placeholder circle with initial
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: DeviceSize.isPad ? 150 : 120, height: DeviceSize.isPad ? 150 : 120)
                                .overlay(
                                    Text(String(profile.name.prefix(1)))
                                        .font(.system(size: DeviceSize.isPad ? 60 : 50, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    
                    // Content Section
                    VStack(alignment: .leading, spacing: DeviceSize.isPad ? 24 : 20) {
                        // Name
                        Text(profile.name)
                            .font(.system(size: DeviceSize.isPad ? 36 : 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, DeviceSize.isPad ? 30 : 20)
                        
                        // YEAR
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YEAR")
                                .font(.system(size: DeviceSize.captionFontSize, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(profile.year)
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // MAJOR
                        VStack(alignment: .leading, spacing: 8) {
                            Text("MAJOR")
                                .font(.system(size: DeviceSize.captionFontSize, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(profile.major)
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // LOCATION
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LOCATION")
                                .font(.system(size: DeviceSize.captionFontSize, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(profile.location)
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        // BIO
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BIO")
                                .font(.system(size: DeviceSize.captionFontSize, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(profile.bio)
                                .font(.system(size: DeviceSize.bodyFontSize))
                                .foregroundColor(.white)
                                .lineSpacing(4)
                        }
                        
                        // INTERESTS
                        VStack(alignment: .leading, spacing: 12) {
                            Text("INTERESTS")
                                .font(.system(size: DeviceSize.captionFontSize, weight: .semibold))
                                .foregroundColor(.gray)
                            
                            // Wrap interests in a flexible layout
                            FlowLayout(spacing: 8) {
                                ForEach(profile.interests, id: \.self) { interest in
                                    Text(interest)
                                        .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, DeviceSize.isPad ? 16 : 12)
                                        .padding(.vertical, DeviceSize.isPad ? 10 : 8)
                                        .background(Color.getActiveRed)
                                        .cornerRadius(20)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.bottom, DeviceSize.tabBarHeight + 20)
                }
            }
        }
        .onAppear {
            loadProfileImage()
        }
    }
    
    private func loadProfileImage() {
        // Load profile image if available
        if let imageName = profile.profileImageName {
            // In a real app, you'd load from URL or local storage
            Task {
                // Simulate loading - in real app, load from storage/URL
                await MainActor.run {
                    // Placeholder - you can add actual image loading here
                }
            }
        }
    }
}

// FlowLayout helper for wrapping interests
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.width ?? 0,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

struct FriendFinderFilterView: View {
    let availableInterests: [String]
    let availableMajors: [String]
    let availableYears: [String]
    @Binding var selectedInterests: Set<String>
    @Binding var selectedMajors: Set<String>
    @Binding var selectedYears: Set<String>
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
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
                    
                    Text("Filter Profiles")
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
                
                ScrollView {
                    VStack(alignment: .leading, spacing: DeviceSize.isPad ? 30 : 24) {
                        // Interests Section
                        VStack(alignment: .leading, spacing: DeviceSize.isPad ? 16 : 12) {
                            Text("Interests")
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Select interests to find matching students")
                                .font(.system(size: DeviceSize.captionFontSize))
                                .foregroundColor(.gray)
                            
                            FlowLayout(spacing: 12) {
                                ForEach(availableInterests, id: \.self) { interest in
                                    Button(action: {
                                        if selectedInterests.contains(interest) {
                                            selectedInterests.remove(interest)
                                        } else {
                                            selectedInterests.insert(interest)
                                        }
                                    }) {
                                        Text(interest)
                                            .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                            .foregroundColor(selectedInterests.contains(interest) ? .white : .gray)
                                            .padding(.horizontal, DeviceSize.isPad ? 18 : 16)
                                            .padding(.vertical, DeviceSize.isPad ? 12 : 10)
                                            .background(selectedInterests.contains(interest) ? Color.getActiveRed : Color.gray.opacity(0.2))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedInterests.contains(interest) ? Color.getActiveRed : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        
                        // Major Section
                        VStack(alignment: .leading, spacing: DeviceSize.isPad ? 16 : 12) {
                            Text("Major")
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Filter by academic major")
                                .font(.system(size: DeviceSize.captionFontSize))
                                .foregroundColor(.gray)
                            
                            FlowLayout(spacing: 12) {
                                ForEach(availableMajors, id: \.self) { major in
                                    Button(action: {
                                        if selectedMajors.contains(major) {
                                            selectedMajors.remove(major)
                                        } else {
                                            selectedMajors.insert(major)
                                        }
                                    }) {
                                        Text(major)
                                            .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                            .foregroundColor(selectedMajors.contains(major) ? .white : .gray)
                                            .padding(.horizontal, DeviceSize.isPad ? 18 : 16)
                                            .padding(.vertical, DeviceSize.isPad ? 12 : 10)
                                            .background(selectedMajors.contains(major) ? Color.getActiveRed : Color.gray.opacity(0.2))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedMajors.contains(major) ? Color.getActiveRed : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        
                        // Graduation Year Section
                        VStack(alignment: .leading, spacing: DeviceSize.isPad ? 16 : 12) {
                            Text("Graduation Year")
                                .font(.system(size: DeviceSize.bodyFontSize + 2, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Filter by graduation year")
                                .font(.system(size: DeviceSize.captionFontSize))
                                .foregroundColor(.gray)
                            
                            FlowLayout(spacing: 12) {
                                ForEach(availableYears, id: \.self) { year in
                                    Button(action: {
                                        if selectedYears.contains(year) {
                                            selectedYears.remove(year)
                                        } else {
                                            selectedYears.insert(year)
                                        }
                                    }) {
                                        Text(year)
                                            .font(.system(size: DeviceSize.bodyFontSize, weight: .medium))
                                            .foregroundColor(selectedYears.contains(year) ? .white : .gray)
                                            .padding(.horizontal, DeviceSize.isPad ? 18 : 16)
                                            .padding(.vertical, DeviceSize.isPad ? 12 : 10)
                                            .background(selectedYears.contains(year) ? Color.getActiveRed : Color.gray.opacity(0.2))
                                            .cornerRadius(20)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(selectedYears.contains(year) ? Color.getActiveRed : Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        
                        // Clear and Apply buttons
                        HStack(spacing: DeviceSize.isPad ? 20 : 15) {
                            Button(action: {
                                selectedInterests.removeAll()
                                selectedMajors.removeAll()
                                selectedYears.removeAll()
                            }) {
                                Text("Clear All")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DeviceSize.buttonHeight)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                onApply()
                                dismiss()
                            }) {
                                Text("Apply Filter")
                                    .font(.system(size: DeviceSize.bodyFontSize, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DeviceSize.buttonHeight)
                                    .background(Color.getActiveRed)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, DeviceSize.horizontalPadding)
                        .padding(.top, DeviceSize.isPad ? 30 : 20)
                        .padding(.bottom, DeviceSize.tabBarHeight + 20)
                    }
                    .padding(.top, DeviceSize.isPad ? 10 : 5)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    FriendFinderView()
        .environmentObject(AuthenticationManager())
}




