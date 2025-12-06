import SwiftUI

enum TutorialStep: Int, CaseIterable {
    case welcome = 0
    case likeAndGoing = 1
    case nextDoor = 2
    case map = 3
    case favorites = 4
    case profile = 5
    case complete = 6
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Get Active!"
        case .likeAndGoing:
            return "Like & Going Buttons"
        case .nextDoor:
            return "Next Door"
        case .map:
            return "Map View"
        case .favorites:
            return "Favorites"
        case .profile:
            return "Profile"
        case .complete:
            return "You're All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Get Active helps you discover and engage with campus events. Let's take a quick tour!"
        case .likeAndGoing:
            return "Tap the heart icon to like events, or tap 'Going' to mark yourself as attending. Liked and attending events appear in your Favorites tab."
        case .nextDoor:
            return "Explore events at nearby universities within an hour's radius of Central State University."
        case .map:
            return "View all campus events on an interactive map. Filter by CSU events or see all events."
        case .favorites:
            return "All your liked events and events you're attending are saved here for easy access."
        case .profile:
            return "Access your profile, settings, and account information. Active Members can also post events and view analytics."
        case .complete:
            return "You're ready to start exploring campus events! Have fun and stay active!"
        }
    }
    
    var highlightTab: Int? {
        switch self {
        case .nextDoor:
            return 1
        case .map:
            return 2
        case .favorites:
            return 3
        case .likeAndGoing, .profile:
            return 0 // Home tab
        default:
            return nil
        }
    }
}

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var authManager = AuthenticationManager()
    @State private var currentStep: TutorialStep = .welcome
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Main app interface (temporarily logged in)
            TutorialTabView(selectedTab: $selectedTab)
                .environmentObject(authManager)
                .disabled(true) // Disable interaction during tutorial
                .opacity(0.7) // Dim the background
            
            // Tutorial overlay
            ZStack {
                // Dark overlay with cutout for highlighted area
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .overlay(
                        // Highlight area (cutout)
                        highlightOverlay
                    )
                
                // Tutorial content card
                VStack {
                    Spacer()
                    
                    tutorialCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            // Temporarily log in for tutorial
            authManager.login(accountType: .undergradAlumni)
            
            // Set initial tab based on step
            if let tab = currentStep.highlightTab {
                selectedTab = tab
            }
        }
        .onChange(of: currentStep) { oldStep, newStep in
            // Switch tabs when needed
            if let tab = newStep.highlightTab {
                withAnimation {
                    selectedTab = tab
                }
            }
        }
    }
    
    @ViewBuilder
    private var highlightOverlay: some View {
        GeometryReader { geometry in
            switch currentStep {
            case .welcome, .complete:
                // No highlight
                EmptyView()
            case .likeAndGoing:
                // Highlight event card area (approximate position)
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.getActiveRed, lineWidth: 4)
                    .frame(width: geometry.size.width - 40, height: 120)
                    .position(x: geometry.size.width / 2, y: geometry.size.height * 0.35)
                    .blur(radius: 0)
            case .nextDoor, .map, .favorites:
                // Highlight tab bar
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.getActiveRed, lineWidth: 4)
                    .frame(width: 80, height: 50)
                    .position(x: getTabPosition(for: currentStep.highlightTab ?? 0, in: geometry), y: geometry.size.height - 30)
            case .profile:
                // Highlight profile button (top right)
                Circle()
                    .stroke(Color.getActiveRed, lineWidth: 4)
                    .frame(width: 50, height: 50)
                    .position(x: geometry.size.width - 50, y: 60)
            }
        }
    }
    
    private func getTabPosition(for tabIndex: Int, in geometry: GeometryProxy) -> CGFloat {
        let tabBarWidth = geometry.size.width
        let tabCount = 4
        let tabWidth = tabBarWidth / CGFloat(tabCount)
        return tabWidth * CGFloat(tabIndex) + tabWidth / 2
    }
    
    private var tutorialCard: some View {
        VStack(spacing: 20) {
            // Step indicator
            HStack(spacing: 8) {
                ForEach(0..<TutorialStep.allCases.count - 1, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep.rawValue ? Color.getActiveRed : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 10)
            
            // Title
            Text(currentStep.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Description
            Text(currentStep.description)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)
            
            // Navigation buttons
            HStack(spacing: 15) {
                if currentStep != .welcome {
                    Button(action: {
                        withAnimation {
                            if let previousStep = TutorialStep(rawValue: currentStep.rawValue - 1) {
                                currentStep = previousStep
                            }
                        }
                    }) {
                        Text("Back")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                }
                
                Button(action: {
                    withAnimation {
                        if currentStep == .complete {
                            // Log out before dismissing
                            authManager.logout()
                            dismiss()
                        } else if let nextStep = TutorialStep(rawValue: currentStep.rawValue + 1) {
                            currentStep = nextStep
                        }
                    }
                }) {
                    Text(currentStep == .complete ? "Get Started" : "Next")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.getActiveRed)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .padding(.vertical, 30)
        .background(Color.getActiveBlack)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

// Custom TabView wrapper for tutorial that allows external control
struct TutorialTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(0)
                .tabItem {
                    Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
                }
            
            NextDoorView()
                .tag(1)
                .tabItem {
                    Label("Next Door", systemImage: selectedTab == 1 ? "building.2.fill" : "building.2")
                }
            
            MapView()
                .tag(2)
                .tabItem {
                    Label("Map", systemImage: "map")
                }
            
            FavoritesView()
                .tag(3)
                .tabItem {
                    Label("Favorites", systemImage: selectedTab == 3 ? "heart.fill" : "heart")
                }
        }
        .accentColor(.getActiveRed)
        .onAppear {
            UITabBar.appearance().backgroundColor = UIColor(Color.getActiveBlack)
            UITabBar.appearance().barTintColor = UIColor(Color.getActiveBlack)
            UITabBar.appearance().unselectedItemTintColor = .white
        }
    }
}

#Preview {
    TutorialView()
}

