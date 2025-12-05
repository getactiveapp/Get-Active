import SwiftUI

struct SplashScreenView: View {
    @Binding var showSplash: Bool
    
    var body: some View {
        ZStack {
            // Black background
            Color.getActiveBlack
                .ignoresSafeArea()
            
            // Centered "Get Active" text
            Text("Get Active")
                .font(.system(size: 48, weight: .regular, design: .default))
                .foregroundColor(.white)
        }
        .onAppear {
            // Show splash for 2 seconds, then transition to login
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                withAnimation(.easeOut(duration: 0.3)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(showSplash: .constant(true))
}

