import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView(showSplash: $showSplash)
                    .transition(.opacity)
                    .zIndex(2)
            } else if authManager.isAuthenticated {
                MainTabView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                LoginView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSplash)
        .animation(.easeInOut(duration: 0.25), value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
