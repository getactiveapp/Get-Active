import SwiftUI

struct AddFriendConfirmationView: View {
    let friendName: String
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Checkmark icon
                    ZStack {
                        Circle()
                            .fill(Color.getActiveRed.opacity(0.2))
                            .frame(width: DeviceSize.isPad ? 120 : 100, height: DeviceSize.isPad ? 120 : 100)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: DeviceSize.isPad ? 70 : 60, weight: .bold))
                            .foregroundColor(.getActiveRed)
                    }
                    
                    // Message
                    VStack(spacing: 16) {
                        Text("Friend Request Sent!")
                            .font(.system(size: DeviceSize.isPad ? 32 : 28, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("You sent a friend request to")
                            .font(.system(size: DeviceSize.isPad ? 22 : 18, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Text(friendName)
                            .font(.system(size: DeviceSize.isPad ? 28 : 24, weight: .bold))
                            .foregroundColor(.getActiveRed)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    
                    Spacer()
                    
                    // Action button
                    Button(action: {
                        isPresented = false
                        // Call the onDismiss callback after a brief delay to allow the sheet to dismiss
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss?()
                        }
                    }) {
                        Text("Got it!")
                            .font(.system(size: DeviceSize.isPad ? 20 : 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: DeviceSize.isPad ? 60 : 55)
                            .background(Color.getActiveRed)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, DeviceSize.horizontalPadding)
                    .padding(.bottom, DeviceSize.isPad ? 40 : 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresented = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss?()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
}

#Preview {
    AddFriendConfirmationView(friendName: "Sarah Johnson", isPresented: .constant(true))
}
