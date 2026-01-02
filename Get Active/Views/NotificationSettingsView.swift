import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var eventManager: EventManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedAdvanceMinutes: Int = 30
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notification Settings")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Choose when you want to be notified before events start")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Notification Options
                        VStack(spacing: 12) {
                            NotificationOptionRow(
                                minutes: 15,
                                title: "15 minutes before",
                                description: "Get notified 15 minutes before the event starts",
                                isSelected: selectedAdvanceMinutes == 15,
                                action: {
                                    selectedAdvanceMinutes = 15
                                    savePreference()
                                }
                            )
                            
                            NotificationOptionRow(
                                minutes: 30,
                                title: "30 minutes before",
                                description: "Get notified 30 minutes before the event starts (Recommended)",
                                isSelected: selectedAdvanceMinutes == 30,
                                action: {
                                    selectedAdvanceMinutes = 30
                                    savePreference()
                                }
                            )
                            
                            NotificationOptionRow(
                                minutes: 50,
                                title: "50 minutes before",
                                description: "Get notified 50 minutes before the event starts",
                                isSelected: selectedAdvanceMinutes == 50,
                                action: {
                                    selectedAdvanceMinutes = 50
                                    savePreference()
                                }
                            )
                        }
                        .padding(.horizontal, 20)
                        
                        // Information Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What notifications will you receive?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                NotificationInfoRow(icon: "bell.fill", text: "Advance notification (based on your selection above)")
                                NotificationInfoRow(icon: "play.fill", text: "Notification when the event starts")
                                NotificationInfoRow(icon: "checkmark.circle.fill", text: "Survey notification at the end of the event")
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.getActiveRed)
                }
            }
        }
        .onAppear {
            selectedAdvanceMinutes = authManager.currentUser?.notificationAdvanceMinutes ?? 30
        }
    }
    
    private func savePreference() {
        guard var user = authManager.currentUser else { return }
        user.notificationAdvanceMinutes = selectedAdvanceMinutes
        authManager.updateUser(user)
        
        // Reschedule all notifications with new preference
        let userId = user.id
        Task {
            await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                NotificationManager.shared.scheduleNotificationsForAllLikedEvents(
                    events: eventManager.events,
                    userId: userId,
                    advanceMinutes: selectedAdvanceMinutes
                )
            }
        }
    }
}

struct NotificationOptionRow: View {
    let minutes: Int
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.getActiveRed : Color.gray.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.getActiveRed)
                            .frame(width: 14, height: 14)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(16)
            .background(isSelected ? Color.getActiveRed.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.getActiveRed : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NotificationInfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.getActiveRed)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

#Preview {
    NotificationSettingsView()
        .environmentObject(AuthenticationManager())
        .environmentObject(EventManager())
}
