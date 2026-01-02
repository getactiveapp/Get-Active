import SwiftUI

struct NextDoorView: View {
    @StateObject private var universityManager = UniversityManager()
    @EnvironmentObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingProfile = false
    @State private var showingChatBot = false
    @State private var selectedUniversity: University?
    
    var body: some View {
        ZStack {
            Color.getActiveBlack.ignoresSafeArea()
            
            VStack(spacing: 0) {
                    // Header
                    ZStack {
                        // Centered title
                        Text("Next Door")
                            .font(.system(size: DeviceSize.titleFontSize, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Right side buttons
                        HStack {
                            Spacer()
                            
                            // Guard Shield Icon and Profile button (top right)
                            HStack(spacing: DeviceSize.isPad ? 16 : 12) {
                                Button(action: {
                                    showingChatBot = true
                                }) {
                                    Image(systemName: "shield.fill")
                                        .font(.system(size: DeviceSize.isPad ? 28 : 24, weight: .semibold))
                                        .foregroundColor(.getActiveRed)
                                        .frame(width: DeviceSize.isPad ? 48 : 40, height: DeviceSize.isPad ? 48 : 40)
                                }
                                
                                Button(action: {
                                    showingProfile = true
                                }) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: DeviceSize.isPad ? 48 : 40, height: DeviceSize.isPad ? 48 : 40)
                                        .overlay(
                                            Text("J")
                                                .font(.system(size: DeviceSize.isPad ? 22 : 18, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.top, DeviceSize.isPad ? 20 : 10)
                    
                    // Main Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nearby Universities")
                                    .font(.system(size: DeviceSize.isPad ? 32 : 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("Discover events at neighboring campuses")
                                    .font(.system(size: DeviceSize.bodyFontSize))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal, DeviceSize.horizontalPadding)
                            .padding(.top, DeviceSize.isPad ? 20 : 10)
                            
                            // University List - Use grid on iPad
                            if DeviceSize.isPad {
                                LazyVGrid(columns: DeviceSize.adaptiveColumns(minWidth: 350), spacing: 20) {
                                    ForEach(universityManager.nearbyUniversities) { university in
                                        Button(action: {
                                            selectedUniversity = university
                                        }) {
                                            UniversityCard(university: university)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, DeviceSize.horizontalPadding)
                                .padding(.top, 20)
                                .padding(.bottom, 100)
                            } else {
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
                                .padding(.horizontal, DeviceSize.horizontalPadding)
                                .padding(.top, 20)
                                .padding(.bottom, 100)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showingChatBot) {
                NavigationView {
                    ChatBotView()
                        .environmentObject(authManager)
                        .environmentObject(eventManager)
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

