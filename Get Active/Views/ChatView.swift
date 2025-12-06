import SwiftUI

struct ChatView: View {
    let friendId: String
    let friendName: String
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.getActiveBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages List
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(messages) { message in
                                ChatMessageBubble(message: message, isFromCurrentUser: message.senderId == authManager.currentUser?.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    
                    // Message Input
                    HStack(spacing: 12) {
                        TextField("Type a message...", text: $messageText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.getActiveRed)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.getActiveBlack)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(friendName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                loadMessages()
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
              let currentUserId = authManager.currentUser?.id,
              let currentUserName = authManager.currentUser?.name else { return }
        
        let messageToSend = messageText.trimmingCharacters(in: .whitespaces)
        
        let newMessage = ChatMessage(
            id: UUID().uuidString,
            senderId: currentUserId,
            receiverId: friendId,
            text: messageToSend,
            timestamp: Date()
        )
        
        messages.append(newMessage)
        
        // Send notification to the friend who received the message
        NotificationManager.shared.sendMessageNotification(
            fromUserName: currentUserName,
            messageText: messageToSend,
            toUserId: friendId,
            fromUserId: currentUserId
        )
        
        messageText = ""
    }
    
    private func loadMessages() {
        // Load existing messages - in a real app, this would fetch from a backend
        // For now, we'll start with an empty array
        messages = []
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(isFromCurrentUser ? .white : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromCurrentUser ? Color.getActiveRed : Color.gray.opacity(0.3))
                    .cornerRadius(16)
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date
}

