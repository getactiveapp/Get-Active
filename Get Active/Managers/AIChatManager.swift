import Foundation

class AIChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    
    struct ChatMessage: Identifiable {
        let id: String
        let text: String
        let isUser: Bool
        let timestamp: Date
    }
    
    func sendMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(
            id: UUID().uuidString,
            text: text,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // Generate AI response
        let response = generateResponse(for: text)
        let aiMessage = ChatMessage(
            id: UUID().uuidString,
            text: response,
            isUser: false,
            timestamp: Date()
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.messages.append(aiMessage)
        }
    }
    
    private func generateResponse(for input: String) -> String {
        let lowercased = input.lowercased()
        
        // Simple keyword-based responses (in production, this would use a real AI API)
        if lowercased.contains("event") || lowercased.contains("what") {
            if lowercased.contains("today") {
                return "There are several events happening today! Check the 'Happening Today' section on the Home tab to see all events scheduled for today."
            } else if lowercased.contains("location") || lowercased.contains("where") {
                return "You can find event locations in the event details. You can also use the Map tab to see all events plotted on a map. Would you like me to help you find a specific event location?"
            } else {
                return "I can help you find events! You can browse events on the Home tab, check out nearby universities on Next Door, or search for specific events. What type of event are you looking for?"
            }
        } else if lowercased.contains("location") || lowercased.contains("where") || lowercased.contains("map") {
            return "You can use the Map tab at the bottom of the screen to see all events on an interactive map. The map shows event locations and you can tap on them for more details. Is there a specific location you're looking for?"
        } else if lowercased.contains("favorite") || lowercased.contains("like") {
            return "To like an event, tap the heart icon on any event card. Your liked events will appear in the Favorites tab. You can also see which events your friends have liked in the 'Friends' Activities' section on the Home tab."
        } else if lowercased.contains("next door") || lowercased.contains("other university") || lowercased.contains("nearby") {
            return "The Next Door feature shows events at universities within an hour's drive of Central State University. Tap the Next Door tab to see nearby universities and their events. You can discover events at places like Wilberforce, Wright State, and more!"
        } else if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            return "Hello! I'm The Guard, your AI assistant for Get Active. I can help you find events, locations, answer questions about the app, and more. What would you like to know?"
        } else if lowercased.contains("help") {
            return "I'm here to help! I can assist you with:\n• Finding events and their locations\n• Using the map feature\n• Understanding how favorites work\n• Discovering events at nearby universities\n• And much more!\n\nWhat do you need help with?"
        } else {
            return "I'm The Guard, your AI assistant for Get Active. I can help you find events, navigate the app, answer questions about locations, and more. Feel free to ask me anything about events or the app!"
        }
    }
}

