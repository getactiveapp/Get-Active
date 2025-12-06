# OpenAI API Setup for The Guard Chatbot

## Configuration

To enable OpenAI integration for The Guard chatbot, you need to set your OpenAI API key.

### Option 1: Environment Variable (Recommended for Development)

Set the environment variable `OPENAI_API_KEY` in Xcode:
1. Go to Product > Scheme > Edit Scheme...
2. Select "Run" in the left sidebar
3. Go to the "Arguments" tab
4. Under "Environment Variables", add:
   - Name: `OPENAI_API_KEY`
   - Value: `your-api-key-here`

### Option 2: Direct Configuration (Not Recommended for Production)

Edit `AIChatManager.swift` and replace:
```swift
return "YOUR_OPENAI_API_KEY_HERE"
```
with your actual API key.

### Option 3: Secure Storage (Recommended for Production)

For production apps, store the API key securely using:
- Keychain Services
- Environment configuration files (excluded from git)
- Secure backend proxy server

## Content Moderation

The chatbot is configured with strict content moderation:
- Automatically filters restricted topics before sending to OpenAI
- Uses a comprehensive system prompt to guide AI responses
- Double-checks AI responses before displaying to users
- Falls back to safe local responses if API is unavailable

## Fallback Mode

If the API key is not set or the API is unavailable, the chatbot will use intelligent fallback responses that still provide helpful information about the Get Active app.

## API Usage

The chatbot uses:
- Model: `gpt-4o-mini` (cost-effective, can be upgraded to `gpt-4`)
- Temperature: 0.8 (for varied responses)
- Max tokens: 300
- Presence penalty: 0.6 (encourages varied responses)

## Restricted Topics

The chatbot will NOT discuss:
- Racism, sexism, or discrimination
- Phobias (homophobia, transphobia, xenophobia, etc.)
- Explicit sexual content
- Violence or graphic content
- Hate speech
- Illegal activities
- Controversial political topics
- Any non-family-friendly content

If users ask about these topics, the chatbot will politely decline and redirect to app-related topics.

