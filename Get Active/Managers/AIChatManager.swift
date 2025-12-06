import Foundation

class AIChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var isThinking = false
    
    // Dependencies
    var eventManager: EventManager?
    var campusInfoManager: CampusInfoManager = CampusInfoManager.shared
    
    // Conversation memory key for UserDefaults
    private let conversationMemoryKey = "AIChatManager_ConversationHistory"
    
    // OpenAI API Configuration
    // NOTE: In production, store this securely in Keychain or environment variables
    // For now, you'll need to set your OpenAI API key here or via environment variable
    private let apiKey: String = {
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            return key
        }
        // Fallback: Replace with your API key or load from secure storage
        return "YOUR_OPENAI_API_KEY_HERE" // Replace with actual key
    }()
    
    private let apiURL = "https://api.openai.com/v1/chat/completions"
    
    struct ChatMessage: Identifiable, Codable {
        let id: String
        let text: String
        let isUser: Bool
        let timestamp: Date
        
        enum CodingKeys: String, CodingKey {
            case id, text, isUser, timestamp
        }
        
        init(id: String = UUID().uuidString, text: String, isUser: Bool, timestamp: Date = Date()) {
            self.id = id
            self.text = text
            self.isUser = isUser
            self.timestamp = timestamp
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            text = try container.decode(String.self, forKey: .text)
            isUser = try container.decode(Bool.self, forKey: .isUser)
            let timestampSeconds = try container.decode(TimeInterval.self, forKey: .timestamp)
            timestamp = Date(timeIntervalSince1970: timestampSeconds)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(text, forKey: .text)
            try container.encode(isUser, forKey: .isUser)
            try container.encode(timestamp.timeIntervalSince1970, forKey: .timestamp)
        }
    }
    
    init() {
        loadConversationHistory()
    }
    
    // Load conversation history from persistent storage
    private func loadConversationHistory() {
        if let data = UserDefaults.standard.data(forKey: conversationMemoryKey),
           let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            // Only load messages from the last 30 days to keep memory fresh
            let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            messages = decoded.filter { $0.timestamp >= thirtyDaysAgo }
            saveConversationHistory()
        }
    }
    
    // Save conversation history to persistent storage
    private func saveConversationHistory() {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: conversationMemoryKey)
        }
    }
    
    // Clear conversation history
    func clearConversationHistory() {
        messages.removeAll()
        UserDefaults.standard.removeObject(forKey: conversationMemoryKey)
    }
    
    // System prompt with strict content moderation - will be enhanced with dynamic data
    private func getSystemPrompt() -> String {
        let basePrompt = """
        You are The Guard, a friendly and helpful AI assistant for the Get Active app at Central State University. You can answer ANY question the user asks, as long as you follow the content restrictions below. You are not limited to just app-related questions - you can discuss general topics, provide information, help with questions, and engage in conversation.
        
        IMPORTANT - THINKING AND REASONING PROCESS:
        Before responding to any question, follow this thinking process:
        1. UNDERSTAND: Carefully read and understand what the user is asking
        2. CONTEXT: Consider the conversation history - remember what you've discussed before
        3. ANALYZE: Break down complex questions into smaller parts if needed
        4. REASON: Think through the logic and reasoning needed to answer accurately
        5. VERIFY: Consider if your answer is accurate, helpful, and appropriate
        6. RESPOND: Provide a clear, well-reasoned response
        
        MEMORY AND CONTEXT:
        - You have access to the full conversation history (up to 30 previous messages)
        - Remember details users mention and reference them naturally in later responses
        - If a user mentions something earlier, acknowledge it and build on it
        - Show that you're paying attention to the conversation flow
        - Make connections between different topics discussed in the conversation
        
        CRITICAL CONTENT RESTRICTIONS - YOU MUST FOLLOW THESE AT ALL TIMES:
        1. NEVER discuss, reference, or engage with topics related to:
           - Racism, racial discrimination, or racial slurs
           - Sexism, gender discrimination, or sexist content
           - Any form of phobias (homophobia, transphobia, xenophobia, etc.)
           - Explicit sexual content, pornography, or sexual topics
           - Violence, graphic content, or disturbing material
           - Hate speech or discriminatory language
           - Illegal activities or substances
           - Controversial political topics or debates
           - Any content that is not family-friendly or appropriate for a university student community
        
        2. If asked about restricted topics, politely decline and redirect:
           "I'm here to help with questions and information, but I can't discuss that topic. I'd be happy to help you with something else, or answer questions about Get Active events and campus activities!"
        
        3. For ALL other topics (not restricted above), you can:
           - Answer questions about any subject (science, history, general knowledge, etc.)
           - Provide helpful information and explanations
           - Engage in friendly conversation
           - Help with homework, study questions, or academic topics
           - Discuss hobbies, interests, and general topics
           - Provide advice and guidance (within appropriate bounds)
        
        4. Keep all responses:
           - Family-friendly and appropriate for all ages
           - Respectful and inclusive
           - Helpful and informative
           - Professional but warm and friendly
           - Well-reasoned and accurate
        
        5. Vary your responses naturally - don't repeat the same phrases. Use different wording and approaches each time.
        
        6. ACCURACY AND QUALITY:
           - Take your time to provide accurate, thoughtful answers
           - If you're uncertain about something, acknowledge it and provide the best answer you can
           - Double-check facts when providing information
           - Provide sources or context when helpful
        
        7. IMPORTANT - You have access to real-time event and campus information:
        """
        
        var prompt = basePrompt
        
        // Add current events information
        if let eventManager = eventManager {
            let events = eventManager.getAllEventsSorted()
            let now = Date()
            
            let upcomingEvents = events.filter { $0.date >= now }.prefix(10)
            
            if !upcomingEvents.isEmpty {
                prompt += "\n\nCURRENT EVENTS ON CAMPUS:\n"
                for event in upcomingEvents {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "MMMM d, yyyy"
                    let dateStr = dateFormatter.string(from: event.date)
                    
                    prompt += """
                    • \(event.title)
                      Date: \(dateStr)
                      Time: \(event.startTime) - \(event.endTime)
                      Location: \(event.location)
                      Description: \(event.description)
                      Category: \(event.category.rawValue)
                    \n
                    """
                }
            }
        }
        
        // Add campus building information
        prompt += "\n\nCAMPUS BUILDINGS AT CENTRAL STATE UNIVERSITY:\n"
        prompt += campusInfoManager.getAllBuildingsInfo()
        
        prompt += """
        
        6. When users ask about events:
           - Provide specific details from the events listed above
           - Include date, time, location, and description
           - Help them find events happening today, this week, or upcoming
           - Mention if an event is happening at a specific building
        
        7. When users ask about buildings or locations:
           - Provide the building hours from the information above
           - Help them find where events are located
           - Answer questions about building accessibility or features
        
        8. When helping with app features, provide specific, actionable information about:
           - Finding events on different tabs (Home, Next Door, Favorites, Map)
           - Using app features (liking events, calendar integration, friend activities)
           - Event locations and details
           - Tips for discovering new events
        """
        
        return prompt
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
        saveConversationHistory() // Save immediately after adding user message
        
        // Check for restricted content before sending to API
        if containsRestrictedContent(text) {
            let response = "I'm here to help with Get Active app questions, events, and campus activities. I can't discuss that topic, but I'd be happy to help you find events or answer questions about the app!"
            addAIMessage(response)
            return
        }
        
        // Show thinking state for better UX and to simulate processing time
        isThinking = true
        isLoading = true
        
        // Call OpenAI API with thinking delay for more accurate responses
        Task {
            // Add a thinking delay to give the AI time to process (1-3 seconds)
            // This simulates real thinking time and can improve response quality
            let thinkingDelay = Double.random(in: 1.0...3.0)
            try? await Task.sleep(nanoseconds: UInt64(thinkingDelay * 1_000_000_000))
            
            await generateOpenAIResponse(for: text)
        }
    }
    
    private func containsRestrictedContent(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let restrictedKeywords = [
            // Explicit content
            "sex", "porn", "nude", "naked", "erotic",
            // Hate speech indicators
            "racist", "sexist", "homophobic", "transphobic", "xenophobic",
            "nazi", "kkk", "slur",
            // Violence
            "kill", "murder", "violence", "assault", "weapon",
            // Illegal substances
            "drug", "cocaine", "heroin", "marijuana",
            // Controversial topics that shouldn't be discussed
            "political party", "election fraud", "conspiracy"
        ]
        
        return restrictedKeywords.contains { keyword in
            lowercased.contains(keyword)
        }
    }
    
    private func generateOpenAIResponse(for userInput: String) async {
        guard apiKey != "YOUR_OPENAI_API_KEY_HERE" else {
            // Fallback to local responses if API key not set
            await MainActor.run {
                let response = generateFallbackResponse(for: userInput)
                addAIMessage(response)
            }
            return
        }
        
        // Build conversation history
        var conversationHistory: [[String: String]] = []
        
        // Add system message with current event and building data
        conversationHistory.append([
            "role": "system",
            "content": getSystemPrompt()
        ])
        
        // Add recent conversation history (last 30 messages for better context and memory)
        // This allows the AI to remember much more of the conversation
        let recentMessages = Array(messages.suffix(30))
        for message in recentMessages {
            conversationHistory.append([
                "role": message.isUser ? "user" : "assistant",
                "content": message.text
            ])
        }
        
        // Add current user message
        conversationHistory.append([
            "role": "user",
            "content": userInput
        ])
        
        // Prepare request - unlimited responses (no max_tokens limit)
        // Using GPT-4o-mini but with enhanced settings for better reasoning
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini", // Using mini for cost efficiency, can upgrade to gpt-4o if needed
            "messages": conversationHistory,
            "temperature": 0.7, // Slightly lower for more focused, accurate responses
            // Removed max_tokens to allow unlimited responses
            "presence_penalty": 0.6, // Encourages more varied responses
            "frequency_penalty": 0.3 // Reduces repetition
        ]
        
        guard let url = URL(string: apiURL) else {
            await MainActor.run {
                addAIMessage("I'm having trouble connecting right now. Please try again!")
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                await MainActor.run {
                    addAIMessage("I'm having trouble connecting right now. Please try again!")
                }
                return
            }
            
            // Parse response
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                
                // Final content moderation check
                let sanitizedResponse = sanitizeResponse(content)
                
                await MainActor.run {
                    addAIMessage(sanitizedResponse)
                }
            } else {
                await MainActor.run {
                    addAIMessage("I'm having trouble processing that. Could you try rephrasing your question?")
                }
            }
        } catch {
            print("OpenAI API Error: \(error.localizedDescription)")
            await MainActor.run {
                isThinking = false
                // Fallback to local responses
                let response = generateFallbackResponse(for: userInput)
                addAIMessage(response)
            }
        }
    }
    
    private func sanitizeResponse(_ response: String) -> String {
        // Double-check response doesn't contain restricted content
        if containsRestrictedContent(response) {
            return "I'm here to help with Get Active app questions, events, and campus activities. How can I assist you with the app?"
        }
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func addAIMessage(_ text: String) {
        let aiMessage = ChatMessage(
            id: UUID().uuidString,
            text: text,
            isUser: false,
            timestamp: Date()
        )
        messages.append(aiMessage)
        saveConversationHistory() // Save after adding AI response
        isLoading = false
        isThinking = false
    }
    
    // Fallback responses when API is unavailable or key not set
    private func generateFallbackResponse(for input: String) -> String {
        let lowercased = input.lowercased()
        
        // Event-related responses with variation
        if lowercased.contains("event") {
            if lowercased.contains("today") {
                let variations = [
                    "There are several events happening today! Check the 'Happening Today' section on the Home tab to see all events scheduled for today.",
                    "You can find today's events in the 'Happening Today' section on your Home screen. Take a look to see what's going on!",
                    "Events happening today are featured in the 'Happening Today' section. Swipe through the Home tab to discover them."
                ]
                return variations.randomElement() ?? variations[0]
            } else if lowercased.contains("location") || lowercased.contains("where") {
                let variations = [
                    "You can find event locations in the event details. You can also use the Map tab to see all events plotted on a map. Would you like me to help you find a specific event location?",
                    "Event locations are shown in each event's details page. Try using the Map tab for a visual overview of all event locations!",
                    "Check the event details for locations, or explore the Map tab to see events plotted geographically."
                ]
                return variations.randomElement() ?? variations[0]
            } else {
                let variations = [
                    "I can help you find events! You can browse events on the Home tab, check out nearby universities on Next Door, or search for specific events. What type of event are you looking for?",
                    "Discover events on the Home tab, explore nearby campuses with Next Door, or use Favorites to track events you're interested in. What are you in the mood for?",
                    "There are multiple ways to find events: browse the Home feed, explore Next Door for nearby universities, or check your Favorites. What would you like to discover?"
                ]
                return variations.randomElement() ?? variations[0]
            }
        } else if lowercased.contains("location") || lowercased.contains("where") || lowercased.contains("map") {
            let variations = [
                "You can use the Map tab at the bottom of the screen to see all events on an interactive map. The map shows event locations and you can tap on them for more details. Is there a specific location you're looking for?",
                "The Map tab gives you a visual overview of all events. Tap on any marker to learn more about that event!",
                "Explore events geographically using the Map tab. It's a great way to see what's happening near you!"
            ]
            return variations.randomElement() ?? variations[0]
        } else if lowercased.contains("favorite") || lowercased.contains("like") {
            let variations = [
                "To like an event, tap the heart icon on any event card. Your liked events will appear in the Favorites tab. You can also see which events your friends have liked in the 'Friends' Activities' section on the Home tab.",
                "Simply tap the heart icon to like events! All your favorites will show up in the Favorites tab. Check out what your friends are interested in too!",
                "Use the heart button to save events you're interested in. They'll all be saved to your Favorites tab for easy access later."
            ]
            return variations.randomElement() ?? variations[0]
        } else if lowercased.contains("next door") || lowercased.contains("other university") || lowercased.contains("nearby") {
            let variations = [
                "The Next Door feature shows events at universities within an hour's drive of Central State University. Tap the Next Door tab to see nearby universities and their events. You can discover events at places like Wilberforce, Wright State, and more!",
                "Next Door lets you explore events at nearby campuses! It's a great way to discover what's happening at other universities close by.",
                "Check out the Next Door tab to see events from universities near Central State. Expand your event horizons!"
            ]
            return variations.randomElement() ?? variations[0]
        } else if lowercased.contains("hello") || lowercased.contains("hi") || lowercased.contains("hey") {
            let variations = [
                "Hello! I'm The Guard, your AI assistant for Get Active. I can help you find events, locations, answer questions about the app, and more. What would you like to know?",
                "Hi there! I'm The Guard, here to help you navigate Get Active and discover amazing events. How can I assist you today?",
                "Hey! Welcome to Get Active. I'm The Guard, your assistant for finding events and using the app. What can I help you with?"
            ]
            return variations.randomElement() ?? variations[0]
        } else if lowercased.contains("help") {
            let variations = [
                "I'm here to help! I can assist you with:\n• Finding events and their locations\n• Using the map feature\n• Understanding how favorites work\n• Discovering events at nearby universities\n• And much more!\n\nWhat do you need help with?",
                "Happy to assist! I can help you:\n• Discover events across different tabs\n• Navigate the map to find locations\n• Manage your favorites\n• Explore nearby campus events\n\nWhat would you like to know?",
                "I've got you covered! Here's what I can help with:\n• Event discovery and browsing\n• Using map features\n• Setting up favorites\n• Finding events at other universities\n\nHow can I help?"
            ]
            return variations.randomElement() ?? variations[0]
        } else {
            let variations = [
                "I'm The Guard, your AI assistant for Get Active. I can help you find events, navigate the app, answer questions about locations, and more. Feel free to ask me anything about events or the app!",
                "I'm here to help you get the most out of Get Active! Whether you're looking for events, need app navigation help, or have questions about features, just ask!",
                "As The Guard, I'm dedicated to helping you discover events and navigate Get Active smoothly. What would you like to know about the app or upcoming events?"
            ]
            return variations.randomElement() ?? variations[0]
        }
    }
}

