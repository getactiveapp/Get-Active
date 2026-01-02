import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingTutorial = false
    @State private var showingActiveMemberAuth = false
    @State private var showingUndergradAlumniAuth = false
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Top spacing - adaptive based on screen size
                    Spacer()
                        .frame(height: DeviceSize.isSmalliPhone ? 40 : DeviceSize.isStandardiPhone ? 60 : 80)
                    
                    // App Title - adaptive font size
                    Text("Get Active")
                        .font(.system(size: DeviceSize.isSmalliPhone ? 36 : DeviceSize.isStandardiPhone ? 42 : 48, weight: .bold, design: .default))
                        .foregroundColor(.getActiveRed)
                    
                    // Tagline - adaptive font size
                    Text("where students lives come alive")
                        .font(.system(size: DeviceSize.isSmalliPhone ? 14 : DeviceSize.isStandardiPhone ? 16 : 18, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.top, DeviceSize.isSmalliPhone ? 8 : 12)
                    
                    // Middle spacing - flexible
                    Spacer()
                        .frame(minHeight: DeviceSize.isSmalliPhone ? 20 : 40)
                    
                    // Login Buttons
                    VStack(spacing: DeviceSize.isSmalliPhone ? 16 : 20) {
                        // Active Member Button - Black fill with red border, white text
                        Button(action: {
                            showingActiveMemberAuth = true
                        }) {
                            Text("Active Member")
                                .font(.system(size: DeviceSize.isSmalliPhone ? 16 : DeviceSize.isStandardiPhone ? 17 : 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DeviceSize.isSmalliPhone ? 48 : DeviceSize.buttonHeight)
                                .background(Color.getActiveBlack)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.getActiveRed, lineWidth: 1)
                                )
                        }
                        
                        // Undergrad/Alumni Button - Red fill with white text
                        Button(action: {
                            showingUndergradAlumniAuth = true
                        }) {
                            Text("Undergrad/Alumni")
                                .font(.system(size: DeviceSize.isSmalliPhone ? 16 : DeviceSize.isStandardiPhone ? 17 : 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: DeviceSize.isSmalliPhone ? 48 : DeviceSize.buttonHeight)
                                .background(Color.getActiveRed)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    
                    // Join text - adaptive font size
                    Text("Join your campus community")
                        .font(.system(size: DeviceSize.isSmalliPhone ? 14 : DeviceSize.isStandardiPhone ? 15 : 16, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.top, DeviceSize.isSmalliPhone ? 16 : 20)
                    
                    // Bottom spacing - flexible
                    Spacer()
                        .frame(minHeight: DeviceSize.isSmalliPhone ? 20 : 40)
                    
                    // Help Button - Bottom right corner
                    HStack {
                        Spacer()
                        Button(action: {
                            showingTutorial = true
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.getActiveRed, lineWidth: 1)
                                    .frame(width: DeviceSize.isSmalliPhone ? 40 : 44, height: DeviceSize.isSmalliPhone ? 40 : 44)
                                
                                Image(systemName: "questionmark")
                                    .font(.system(size: DeviceSize.isSmalliPhone ? 18 : 20, weight: .medium))
                                    .foregroundColor(.getActiveRed)
                            }
                        }
                        .padding(.trailing, DeviceSize.isSmalliPhone ? 20 : 30)
                        .padding(.bottom, DeviceSize.isSmalliPhone ? 20 : 30)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fullScreenCover(isPresented: $showingTutorial) {
            TutorialView()
        }
        .fullScreenCover(isPresented: $showingActiveMemberAuth) {
            ActiveMemberAuthView()
        }
        .fullScreenCover(isPresented: $showingUndergradAlumniAuth) {
            UndergradAlumniAuthView()
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager())
}

