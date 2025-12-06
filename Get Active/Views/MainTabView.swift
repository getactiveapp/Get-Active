import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var eventManager: EventManager
    @State private var selectedTab = 0
    @State private var showingEventPost = false
    @State private var showingAnalytics = false
    
    var body: some View {
        ZStack {
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
                
                // Request notification permissions and schedule notifications for liked events
                if let userId = authManager.currentUser?.id {
                    Task {
                        let hasPermission = await NotificationManager.shared.requestAuthorization()
                        if hasPermission {
                            await MainActor.run {
                                NotificationManager.shared.scheduleNotificationsForAllLikedEvents(
                                    events: eventManager.events,
                                    userId: userId
                                )
                            }
                        }
                    }
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

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager())
}
