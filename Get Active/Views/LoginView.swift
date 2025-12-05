import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingTutorial = false
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top spacing
                Spacer()
                    .frame(height: 100)
                
                // App Title
                Text("Get Active")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundColor(.getActiveRed)
                
                // Tagline
                Text("where students lives come alive")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.top, 12)
                
                // Middle spacing
                Spacer()
                
                // Login Buttons
                VStack(spacing: 20) {
                    // Active Member Button - Black fill with red border, white text
                    Button(action: {
                        authManager.login(accountType: .activeMember)
                    }) {
                        Text("Active Member")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.getActiveBlack)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.getActiveRed, lineWidth: 1)
                            )
                    }
                    
                    // Undergrad/Alumni Button - Red fill with white text
                    Button(action: {
                        authManager.login(accountType: .undergradAlumni)
                    }) {
                        Text("Undergrad/Alumni")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(Color.getActiveRed)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 40)
                
                // Join text
                Text("Join your campus community")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Bottom spacing
                Spacer()
                
                // Help Button - Bottom right corner
                HStack {
                    Spacer()
                    Button(action: {
                        showingTutorial = true
                    }) {
                        ZStack {
                            Circle()
                                .stroke(Color.getActiveRed, lineWidth: 1)
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "questionmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.getActiveRed)
                        }
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 30)
                }
            }
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView()
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}

