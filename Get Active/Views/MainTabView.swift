import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var eventManager: EventManager
    @StateObject private var featureFlags = FeatureFlagsManager()
    @State private var selectedTab = 0
    @State private var showingEventPost = false
    @State private var showingAnalytics = false
    
    // Computed property to build tabs based on feature flags
    private var tabs: [TabItem] {
        var items: [TabItem] = []
        var tag = 0
        
        // Home is always first
        items.append(TabItem(
            tag: tag,
            view: AnyView(HomeView()),
            label: "Home",
            icon: selectedTab == tag ? "house.fill" : "house"
        ))
        tag += 1
        
        // Next Door (conditional)
        if featureFlags.flags.nextDoorEnabled {
            items.append(TabItem(
                tag: tag,
                view: AnyView(NextDoorView()),
                label: "Next Door",
                icon: selectedTab == tag ? "building.2.fill" : "building.2"
            ))
            tag += 1
        }
        
        // Friend Finder (conditional)
        if featureFlags.flags.friendFinderEnabled {
            items.append(TabItem(
                tag: tag,
                view: AnyView(FriendFinderView()),
                label: "Friend Finder",
                icon: selectedTab == tag ? "person.2.fill" : "person.2"
            ))
            tag += 1
        }
        
        // Map (conditional)
        if featureFlags.flags.mapEnabled {
            items.append(TabItem(
                tag: tag,
                view: AnyView(MapView()),
                label: "Map",
                icon: "map"
            ))
            tag += 1
        }
        
        // Favorites (conditional)
        if featureFlags.flags.favoritesEnabled {
            items.append(TabItem(
                tag: tag,
                view: AnyView(FavoritesView()),
                label: "Favorites",
                icon: selectedTab == tag ? "heart.fill" : "heart"
            ))
            tag += 1
        }
        
        return items
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ForEach(tabs, id: \.tag) { tab in
                    tab.view
                        .tag(tab.tag)
                        .tabItem {
                            Label(tab.label, systemImage: tab.icon)
                        }
                }
            }
            .accentColor(.getActiveRed)
            .onAppear {
                UITabBar.appearance().backgroundColor = UIColor(Color.getActiveBlack)
                UITabBar.appearance().barTintColor = UIColor(Color.getActiveBlack)
                UITabBar.appearance().unselectedItemTintColor = .white
                
                // Load feature flags on app start
                featureFlags.loadFlags()
                
                // Test GitHub connection (for debugging - check Xcode console)
                #if DEBUG
                featureFlags.testGitHubConnection()
                #endif
                
                // Request notification permissions and schedule notifications for liked events
                if let userId = authManager.currentUser?.id {
                    Task {
                        let hasPermission = await NotificationManager.shared.requestAuthorization()
                        if hasPermission {
                            await MainActor.run {
                                let advanceMinutes = authManager.currentUser?.notificationAdvanceMinutes ?? 30
                                NotificationManager.shared.scheduleNotificationsForAllLikedEvents(
                                    events: eventManager.events,
                                    userId: userId,
                                    advanceMinutes: advanceMinutes
                                )
                            }
                        }
                    }
                }
            }
            .onChange(of: featureFlags.flags) { _, _ in
                // Reset to home tab if current tab becomes unavailable
                if !tabs.contains(where: { $0.tag == selectedTab }) {
                    selectedTab = 0
                }
            }
        }
        .sheet(isPresented: $showingEventPost) {
            EventPostingView(eventManager: eventManager)
        }
        .sheet(isPresented: $showingAnalytics) {
            if let firstEvent = eventManager.events.first {
                AnalyticsView(eventManager: eventManager, eventId: firstEvent.id)
            }
        }
    }
}

// Helper struct for tab items
struct TabItem {
    let tag: Int
    let view: AnyView
    let label: String
    let icon: String
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
