import SwiftUI

struct ChatBotView: View {
    @StateObject private var chatManager = AIChatManager()
    @EnvironmentObject var eventManager: EventManager
    @State private var messageText = ""
    @Environment(\.dismiss) var dismiss
    
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
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("The Guard")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("AI Assistant")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    // Clear conversation button
                    if !chatManager.messages.isEmpty {
                        Button(action: {
                            chatManager.clearConversationHistory()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.getActiveRed)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 15) {
                            if chatManager.messages.isEmpty {
                                VStack(spacing: 20) {
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 60))
                                        .foregroundColor(.getActiveRed)
                                    
                                    Text("The Guard")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Text("Your AI assistant for Get Active")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                    
                                    Text("Ask me anything about events, locations, or the app!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                                .padding(.top, 100)
                            } else {
                                ForEach(chatManager.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                                
                                if chatManager.isLoading {
                                    HStack(spacing: 12) {
                                        if chatManager.isThinking {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .getActiveRed))
                                                .scaleEffect(1.2)
                                        } else {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .getActiveRed))
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(chatManager.isThinking ? "The Guard is thinking..." : "The Guard is responding...")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white)
                                            
                                            if chatManager.isThinking {
                                                Text("Taking time to provide an accurate answer")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(.gray)
                                            }
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatManager.messages.count) { oldCount, newCount in
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input Area
                HStack(spacing: 15) {
                    TextField("Ask The Guard...", text: $messageText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(25)
                        .foregroundColor(.white)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: {
                        sendMessage()
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(chatManager.isLoading || messageText.isEmpty ? .gray : .getActiveRed)
                    }
                    .disabled(messageText.isEmpty || chatManager.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
            }
        }
        .onAppear {
            // Set EventManager reference for chatbot
            chatManager.eventManager = eventManager
        }
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        chatManager.sendMessage(messageText)
        messageText = ""
    }
}

struct MessageBubble: View {
    let message: AIChatManager.ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 5) {
                Text(message.text)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser ? Color.getActiveRed : Color.gray.opacity(0.3))
                    .cornerRadius(20)
            }
            
            if !message.isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    ChatBotView()
        .environmentObject(EventManager())
}

