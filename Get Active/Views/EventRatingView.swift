import SwiftUI

struct EventRatingView: View {
    let event: Event
    @ObservedObject var eventManager: EventManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedRating: Int = 0
    @State private var feedbackText: String = ""
    @State private var showingError = false
    
    var hasRated: Bool {
        guard let userId = authManager.currentUser?.id else { return false }
        return event.ratings.contains { $0.userId == userId }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Event Info
                    VStack(spacing: 12) {
                        Text(event.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("How was this event?")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 30)
                    
                    // Star Rating
                    HStack(spacing: 15) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: {
                                selectedRating = star
                            }) {
                                Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                    .font(.system(size: 40))
                                    .foregroundColor(star <= selectedRating ? .yellow : .gray)
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Feedback Text
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Share your feedback (optional)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        TextEditor(text: $feedbackText)
                            .frame(height: 120)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .scrollContentBackground(.hidden)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                    
                    // Submit Button
                    Button(action: {
                        submitRating()
                    }) {
                        Text("Submit Rating")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(selectedRating > 0 ? Color.getActiveRed : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .disabled(selectedRating == 0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.white)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Rate Event")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .alert("Rating Required", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please select a rating from 1 to 5 stars.")
            }
            .onAppear {
                if hasRated, let userId = authManager.currentUser?.id,
                   let existingRating = event.ratings.first(where: { $0.userId == userId }) {
                    selectedRating = existingRating.rating
                    feedbackText = existingRating.feedback
                }
            }
        }
    }
    
    private func submitRating() {
        guard selectedRating > 0,
              let userId = authManager.currentUser?.id else {
            showingError = true
            return
        }
        
        // Update event with rating
        if let index = eventManager.events.firstIndex(where: { $0.id == event.id }) {
            let newRating = EventRating(
                userId: userId,
                rating: selectedRating,
                feedback: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            // Remove existing rating from this user if any
            eventManager.events[index].ratings.removeAll { $0.userId == userId }
            
            // Add new rating
            eventManager.events[index].ratings.append(newRating)
            
            dismiss()
        }
    }
}





