import SwiftUI

@main
struct Get_ActiveApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var eventManager = EventManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(eventManager)
                .preferredColorScheme(.dark)
        }
    }
}
