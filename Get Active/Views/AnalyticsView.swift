import SwiftUI

struct AnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var analyticsManager = AnalyticsManager()
    @ObservedObject var eventManager: EventManager
    let eventId: String
    
    var analytics: EventAnalytics {
        analyticsManager.getAnalytics(for: eventId)
    }
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Event Analytics")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.clear)
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Stats Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            StatBox(title: "Views", value: "\(analytics.views)", icon: "eye.fill")
                            StatBox(title: "Likes", value: "\(analytics.likes)", icon: "heart.fill")
                            StatBox(title: "Attendees", value: "\(analytics.attendees)", icon: "person.2.fill")
                            StatBox(title: "Shares", value: "\(analytics.shares)", icon: "square.and.arrow.up.fill")
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // AI Feedback Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24))
                                    .foregroundColor(.getActiveRed)
                                
                                Text("AI Feedback")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(analytics.aiFeedback)
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                                .padding(16)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.getActiveRed)
            
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    AnalyticsView(eventManager: EventManager(), eventId: "test")
}

