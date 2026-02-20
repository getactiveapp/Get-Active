# OpenAI/ChatGPT Setup for The Guard 🤖

The Guard chatbot is now fully configured to use OpenAI's GPT-4o (ChatGPT) with unlimited responses and complete knowledge of all Get Active events and app features.

## ✅ What's Already Configured

1. **Unlimited Responses**: No token limits - The Guard can give detailed, comprehensive answers
2. **Maximum Response Variation**: Enhanced settings ensure unique responses every time
3. **Complete Event Knowledge**: Access to ALL events (past, current, and future)
4. **Full App Knowledge**: Comprehensive understanding of all Get Active features
5. **Persistent Memory**: Remembers conversation history (last 30 messages)
6. **Content Moderation**: Built-in filters to keep responses family-friendly

## 🔑 Setting Up Your OpenAI API Key

To connect The Guard to ChatGPT, you need to add your OpenAI API key:

### Option 1: Environment Variable (Recommended)

1. Open Xcode
2. Go to **Product → Scheme → Edit Scheme...**
3. Select **Run** in the left sidebar
4. Click the **Arguments** tab
5. Under **Environment Variables**, click the **+** button
6. Add:
   - **Name**: `OPENAI_API_KEY`
   - **Value**: `your-api-key-here`
7. Click **Close**

### Option 2: Direct Code (Temporary)

If you need to test quickly, you can temporarily add your API key directly in the code:

1. Open `/Users/techsgivingsummit/Downloads/Get Active/Get Active/Managers/AIChatManager.swift`
2. Find line 23: `return "YOUR_OPENAI_API_KEY_HERE"`
3. Replace `YOUR_OPENAI_API_KEY_HERE` with your actual OpenAI API key
4. **⚠️ Warning**: Don't commit this to git! Remove it before pushing.

## 🔐 Getting Your OpenAI API Key

1. Go to [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)
2. Sign in or create an account
3. Click **"Create new secret key"**
4. Copy the key (you'll only see it once!)
5. Paste it into Xcode using one of the methods above

## 🎯 Features Enabled

### Unlimited Responses
- Uses **GPT-4o** model (latest ChatGPT technology)
- No response length limits
- Can handle complex, multi-part questions

### Maximum Variation
- **Temperature**: 0.9 (high creativity)
- **Presence Penalty**: 0.8 (encourages new topics)
- **Frequency Penalty**: 0.6 (reduces repetition)
- **Top P**: 0.95 (nucleus sampling for diversity)

### Complete Event Knowledge
- **ALL Events**: Past, current, and future events
- **Today's Events**: Highlighted separately
- **Event Details**: Full descriptions, categories, tags, attendance counts
- **Up to 50 upcoming events** included in knowledge base

### Comprehensive App Knowledge
- All tabs and their features
- Event management (creating, RSVPing, rating)
- Social features (friends, messaging)
- Profile features (settings, analytics)
- Notifications system
- Map and discovery features

### Persistent Memory
- Remembers last 30 messages in conversation
- Can reference earlier parts of the conversation
- Builds on previous discussions naturally

## 🧠 What The Guard Knows

### Events
- All event titles, descriptions, dates, times
- Event locations and categories
- Number of people attending and liking
- Event tags and metadata
- Which events are happening today

### Campus Buildings
- All Central State University buildings
- Building hours and operating times
- Building descriptions and purposes
- Location information

### Get Active App Features
- How to use each tab (Home, Next Door, Map, Favorites, Profile)
- Event features (like, RSVP, "I'm Here!", rating)
- Social features (friends, messaging, activities)
- Profile features (settings, analytics, resources)
- Notification system details

## 🚫 Content Restrictions

The Guard will NOT discuss:
- Explicit or adult content
- Racism, sexism, or discrimination
- Violence or illegal activities
- Controversial political topics
- Any non-family-friendly content

It will politely redirect to appropriate topics.

## 💡 Example Interactions

**User**: "What events are happening today?"
**Guard**: [Unique response with specific event details from today's events]

**User**: "Tell me about the Student Center"
**Guard**: [Unique response with building hours and information]

**User**: "How do I RSVP to an event?"
**Guard**: [Unique, step-by-step explanation of the RSVP process]

**User**: "What's the difference between liking and RSVPing?"
**Guard**: [Unique explanation with examples]

## 🔄 Response Variation

The Guard is configured to give **completely different responses** each time:
- Different wording and phrasing
- Different examples and analogies
- Varied sentence structure
- Unique communication style
- Fresh approaches to similar questions

You'll never get the same response twice!

## 🛠️ Troubleshooting

### "I'm having trouble connecting"
- Check your API key is correct
- Verify you have API credits on your OpenAI account
- Check your internet connection

### Getting same responses
- The Guard uses high variation settings - responses should be unique
- If you see repetition, it may be due to very specific questions
- Try asking the same question differently

### API Key Not Working
- Make sure there are no extra spaces in the key
- Verify the key is active on OpenAI's platform
- Check your OpenAI account has available credits

## 📝 Notes

- The API key should be kept secure and not shared
- For production, consider using secure keychain storage
- API usage will incur costs based on OpenAI's pricing
- The Guard will use intelligent fallback responses if the API is unavailable

Your Guard chatbot is now ready to provide unlimited, varied responses with complete knowledge of Get Active! 🎉





