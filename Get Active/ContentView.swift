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
                // Check if Active Member needs to complete application and payment
                if authManager.pendingActiveMemberApplication {
                    // Show application screen first for Active Members after sign-up
                    ActiveMemberApplicationView {
                        // Application completed - show payment screen next
                        DispatchQueue.main.async {
                            authManager.pendingActiveMemberApplication = false
                            authManager.pendingActiveMemberPayment = true
                        }
                    }
                    .environmentObject(authManager)
                    .transition(.opacity)
                    .zIndex(1)
                } else if authManager.pendingActiveMemberPayment {
                    // Show payment screen for Active Members after application
                    ActiveMemberPaymentView {
                        // Payment completed - clear flag and navigate to Home
                        DispatchQueue.main.async {
                            authManager.pendingActiveMemberPayment = false
                        }
                    } onSkip: {
                        // Skip/cancel payment - clear flag and navigate to Home
                        // (In production, you might want to handle this differently)
                        DispatchQueue.main.async {
                            authManager.pendingActiveMemberPayment = false
                        }
                    }
                    .environmentObject(authManager)
                    .transition(.opacity)
                    .zIndex(1)
                } else {
                    // Normal authenticated state - show Home Screen
                    MainTabView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            } else {
                LoginView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSplash)
        .animation(.easeInOut(duration: 0.25), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.25), value: authManager.pendingActiveMemberApplication)
        .animation(.easeInOut(duration: 0.25), value: authManager.pendingActiveMemberPayment)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
}
