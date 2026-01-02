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
    // Securely stored in Keychain
    private var apiKey: String? {
        // First, try to get from Keychain
        if let key = SecureKeyManager.shared.getOpenAIAPIKey(), !key.isEmpty {
            return key
        }
        // Fallback to environment variable (for development)
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !key.isEmpty {
            // Save to Keychain for future use
            SecureKeyManager.shared.saveOpenAIAPIKey(key)
            return key
        }
        // Return nil if no key found
        return nil
    }
    
    /// Set OpenAI API key securely
    func setOpenAIAPIKey(_ key: String) -> Bool {
        return SecureKeyManager.shared.saveOpenAIAPIKey(key)
    }
    
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
        
        5. RESPONSE VARIATION - CRITICAL:
           - NEVER repeat the exact same response twice, even for similar questions
           - Use completely different wording, structure, and examples each time
           - Vary your sentence length, tone, and communication style
           - Come up with fresh analogies, explanations, and approaches
           - Show creativity in how you express ideas
           - The user should never feel like they're getting canned responses
        
        6. ACCURACY AND QUALITY:
           - Take your time to provide accurate, thoughtful answers
           - If you're uncertain about something, acknowledge it and provide the best answer you can
           - Double-check facts when providing information
           - Provide sources or context when helpful
        
        7. GET ACTIVE APP KNOWLEDGE - You are an expert on the Get Active app:
           - Home Tab: Shows featured events, friends' activities, and events happening today
           - Next Door Tab: Shows events from nearby universities within an hour's drive
           - Map Tab: Displays all events on an interactive map with clickable pins
           - Favorites Tab: Shows events the user has liked or RSVP'd to
           - Profile Tab: User's profile, settings, analytics, and mental health resources
           - Event Features: Users can like events, RSVP to events, mark "I'm Here!" when arriving
           - Notifications: Users get notified 1 hour before events they're attending, and when events start
           - Calendar Integration: Users can link events to their device calendar
           - Friend Activities: See what friends are going to and liked
           - Event Categories: Academic, Technology, Party, Mental Health, Vendor, Club, Career, Prayer, Other
           - RSVP System: Users RSVP first, then confirm "I'm Going" which triggers notifications
           - Event Rating: After events end, users can rate events 1-5 stars and provide feedback
           - Analytics: Event hosts can see views, likes, attendees, ratings, and AI-generated feedback
           - Mental Health Resources: Links to university-specific mental health support
           - Event Creation: Active members can create and post events with images from camera roll
        
        8. IMPORTANT - You have access to ALL event and campus information:
        """
        
        var prompt = basePrompt
        
        // Add ALL events information (past, current, and future)
        if let eventManager = eventManager {
            let allEvents = eventManager.getAllEventsSorted()
            let now = Date()
            let calendar = Calendar.current
            
            // Separate events by time period
            let pastEvents = allEvents.filter { calendar.startOfDay(for: $0.date) < calendar.startOfDay(for: now) }
            let todayEvents = allEvents.filter { calendar.isDateInToday($0.date) }
            let upcomingEvents = allEvents.filter { calendar.startOfDay(for: $0.date) > calendar.startOfDay(for: now) }
            
            if !allEvents.isEmpty {
                prompt += "\n\n=== ALL GET ACTIVE EVENTS ===\n\n"
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM d, yyyy 'at' h:mm a"
                let shortDateFormatter = DateFormatter()
                shortDateFormatter.dateFormat = "MMMM d, yyyy"
                
                // Events happening TODAY
                if !todayEvents.isEmpty {
                    prompt += "EVENTS HAPPENING TODAY (\(todayEvents.count)):\n"
                    for event in todayEvents {
                        prompt += """
                        • \(event.title)
                          Time: \(event.startTime) - \(event.endTime) TODAY
                          Location: \(event.location)
                          Description: \(event.description)
                          Category: \(event.category.rawValue)
                          Tags: \(event.tags.joined(separator: ", "))
                          \(event.attending.count) people attending
                          \(event.likedBy.count) people liked
                        \n
                        """
                    }
                    prompt += "\n"
                }
                
                // Upcoming Events
                if !upcomingEvents.isEmpty {
                    prompt += "UPCOMING EVENTS (\(upcomingEvents.count)):\n"
                    for event in upcomingEvents.prefix(50) { // Include up to 50 upcoming events
                        let dateStr = shortDateFormatter.string(from: event.date)
                        prompt += """
                        • \(event.title)
                          Date: \(dateStr)
                          Time: \(event.startTime) - \(event.endTime)
                          Location: \(event.location)
                          Description: \(event.description)
                          Category: \(event.category.rawValue)
                          Tags: \(event.tags.joined(separator: ", "))
                          \(event.attending.count) people attending
                          \(event.likedBy.count) people liked
                        \n
                        """
                    }
                    if upcomingEvents.count > 50 {
                        prompt += "... and \(upcomingEvents.count - 50) more upcoming events\n\n"
                    }
                }
                
                // Past Events (for context)
                if !pastEvents.isEmpty {
                    prompt += "RECENT PAST EVENTS (\(min(pastEvents.count, 20)) shown):\n"
                    for event in pastEvents.suffix(20) { // Last 20 past events for context
                        let dateStr = shortDateFormatter.string(from: event.date)
                        prompt += """
                        • \(event.title) (Past: \(dateStr))
                          Location: \(event.location)
                          Category: \(event.category.rawValue)
                        \n
                        """
                    }
                    prompt += "\n"
                }
            }
        }
        
        // Add campus building information
        prompt += "\n\nCAMPUS BUILDINGS AT CENTRAL STATE UNIVERSITY:\n"
        prompt += campusInfoManager.getAllBuildingsInfo()
        
        prompt += """
        
        9. COMPREHENSIVE GET ACTIVE APP KNOWLEDGE:
        
        APP STRUCTURE:
        - Home Tab: Main feed with featured events, friends' activities, and "Happening Today" section
        - Next Door Tab: Discover events at nearby universities (Wilberforce, Wright State, Ohio State, etc.)
        - Map Tab: Interactive map showing all events with clickable pins and event index
        - Favorites Tab: All events user has liked or RSVP'd to
        - Profile Tab: User profile, settings, analytics (for event hosts), mental health resources
        
        EVENT FEATURES:
        - Like Button: Heart icon to save events to favorites
        - RSVP Button: First step to attend an event (changes to "I'm Going" after tapping)
        - "I'm Going" Button: Confirms attendance and triggers event notifications
        - "I'm Here!" Button: Available 1 hour before event until event ends, shows "Time to Get Active!" popup
        - Event Rating: After events end, users can rate 1-5 stars and provide feedback
        - Event Images: Events can have custom images uploaded from camera roll
        - Event Categories: Academic, Technology, Party, Mental Health, Vendor, Club, Career, Prayer, Other
        
        NOTIFICATIONS:
        - 1 hour before event (for events user is attending)
        - When event starts (reminds to click "I'm Here!")
        - Friend requests and acceptances
        - Messages from friends
        - Event rating prompts after events end
        
        SOCIAL FEATURES:
        - Friends List: Add and manage friends
        - Friend Activities: See what friends are going to and liked
        - "Join Them" Button: Quickly RSVP to events friends are attending
        - Direct Messaging: Chat with friends within the app
        
        EVENT MANAGEMENT:
        - Create Events: Active members can post events with date, time, location, category, images
        - My Events: View and delete events you created
        - Event Analytics: See views, likes, attendees, ratings, and AI feedback for your events
        - Event Details: Full event information with description, tags, attendee count
        
        PROFILE FEATURES:
        - Account Settings: Edit profile picture and bio
        - Calendar Integration: Link Get Active events to device calendar
        - Mental Health Resources: University-specific wellness and support links
        - Event Statistics: Friends count, events this week, upcoming events
        - Analytics Dashboard: For event hosts (views, likes, attendees, ratings, charts)
        
        SEARCH AND DISCOVERY:
        - Featured Events: Highlighted events on Home tab
        - Happening Today: Today's events in vertical scrollable list
        - All Events: Complete list of all events sorted by date
        - Map View: Visual map of all events with filtering (CSU only or all events)
        - Event Index: Scrollable list under map showing event cards
        
        10. When users ask about events:
           - Provide SPECIFIC details from the events listed above (use exact event names, dates, times)
           - Reference events by their actual titles and locations
           - Help them find events happening today, this week, or upcoming
           - Mention specific building names and their hours if relevant
           - Provide event descriptions, categories, and tags when helpful
        
        11. When users ask about buildings or locations:
           - Provide the exact building hours from the information above
           - Help them find where events are located on campus
           - Answer questions about building accessibility or features
           - Reference specific campus buildings by their full names
        
        12. When helping with app features, provide specific, actionable information:
           - Explain how to use each tab (Home, Next Door, Map, Favorites, Profile)
           - Walk through features step-by-step (liking, RSVPing, calendar integration)
           - Provide tips for discovering new events
           - Help troubleshoot common app usage questions
        
        13. RESPONSE VARIATION REQUIREMENTS:
           - NEVER repeat the same response structure or wording
           - Use completely different examples, analogies, and explanations each time
           - Vary your communication style (formal, casual, enthusiastic, helpful, etc.)
           - Change sentence structure, length, and format
           - Show creativity and personality while staying professional
           - The user should feel like they're talking to a dynamic, intelligent assistant
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
        guard let key = apiKey, !key.isEmpty else {
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
        // Using GPT-4o for best quality and unlimited variation
        let requestBody: [String: Any] = [
            "model": "gpt-4o", // Using GPT-4o for best quality and unlimited responses
            "messages": conversationHistory,
            "temperature": 0.9, // Higher temperature for maximum response variation
            // Removed max_tokens to allow unlimited responses
            "presence_penalty": 0.8, // Higher penalty for maximum response variation
            "frequency_penalty": 0.6, // Higher penalty to reduce repetition significantly
            "top_p": 0.95 // Nucleus sampling for more diverse responses
        ]
        
        guard let url = URL(string: apiURL) else {
            await MainActor.run {
                addAIMessage("I'm having trouble connecting right now. Please try again!")
            }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
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

