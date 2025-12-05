import SwiftUI

struct NextDoorView: View {
    @StateObject private var universityManager = UniversityManager()
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingProfile = false
    @State private var showingChatBot = false
    @State private var selectedUniversity: University?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        
                        Text("Next Door")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Guard Shield Icon and Profile button (top right)
                        HStack(spacing: 12) {
                            Button(action: {
                                showingChatBot = true
                            }) {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.getActiveRed)
                                    .frame(width: 40, height: 40)
                            }
                            
                            Button(action: {
                                showingProfile = true
                            }) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text("J")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Main Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nearby Universities")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Discover events at neighboring campuses")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            // University List
                            VStack(spacing: 12) {
                                ForEach(universityManager.nearbyUniversities) { university in
                                    Button(action: {
                                        selectedUniversity = university
                                    }) {
                                        UniversityCard(university: university)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingChatBot) {
                NavigationView {
                    ChatBotView()
                        .environmentObject(authManager)
                }
            }
            .sheet(item: $selectedUniversity) { university in
                NavigationView {
                    UniversityEventsView(university: university, eventManager: eventManager)
                        .environmentObject(authManager)
                }
            }
        }
    }
}

struct UniversityCard: View {
    let university: University
    
    var body: some View {
        HStack(spacing: 15) {
            // University Icon
            ZStack {
                Circle()
                    .fill(Color.getActiveRed)
                    .frame(width: 50, height: 50)
                
                Text(university.abbreviation)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(university.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 5) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Text(String(format: "%.1f miles away", university.distance))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text("•")
                        .foregroundColor(.gray)
                    
                    Text("\(university.eventCount) events")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NextDoorView()
        .environmentObject(AuthenticationManager())
}

