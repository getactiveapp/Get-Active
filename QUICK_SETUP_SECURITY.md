# Quick Setup Guide - Security Features

## 🚀 Immediate Actions Required

### 1. Set Your OpenAI API Key (Required for AI Chat)

**Option A: Using Code (One-time setup)**
```swift
// Add this to your App.swift or main initialization
import SwiftUI

@main
struct GetActiveApp: App {
    init() {
        // Set OpenAI API key securely
        AIChatManager.shared.setOpenAIAPIKey("sk-your-actual-openai-key-here")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

**Option B: Using Environment Variable (Development)**
- Set `OPENAI_API_KEY` in your Xcode scheme
- Edit Scheme → Run → Arguments → Environment Variables
- Add: `OPENAI_API_KEY` = `sk-your-key-here`
- The key will be automatically saved to Keychain

### 2. Test the Security Features

1. **Test Password Hashing**:
   - Create a new account
   - Check UserDefaults - password should be hashed (not plain text)
   - Try logging in - should work correctly

2. **Test 2FA**:
   - Log in with any account
   - You should see the 2FA screen
   - Enter the 6-digit code shown (demo mode)
   - Should complete login

3. **Test Keychain Storage**:
   - Set OpenAI API key
   - Restart app
   - AI chat should still work (key retrieved from Keychain)

## 📝 What Changed

### For Users:
- **Existing accounts**: Will need to sign up again (passwords are now hashed)
- **New accounts**: Passwords are automatically hashed
- **2FA**: All logins now require 2FA verification (demo mode)

### For Developers:
- **API Keys**: No longer hardcoded - use Keychain
- **Passwords**: Automatically hashed before storage
- **Tokens**: Stored securely in Keychain
- **2FA**: Ready to integrate with email/SMS service

## 🔧 Configuration

### Disable 2FA (For Testing)
If you want to disable 2FA temporarily for testing, modify `AuthenticationManager.swift`:

```swift
// In login() method, comment out the 2FA check:
// if user.email.contains("@") {
//     requires2FA = true
//     pending2FAUserId = user.id
//     completion(false, "2FA_REQUIRED")
//     return
// }
```

### Change 2FA Code Expiration
In `SecureKeyManager.swift`, modify the expiration time:
```swift
func save2FACode(_ code: String, expiresIn seconds: Int = 600) // 600 = 10 minutes
```

## ⚠️ Production Checklist

Before launching to production:

- [ ] Set OpenAI API key securely
- [ ] Remove demo 2FA code display from `TwoFactorAuthView`
- [ ] Implement actual email/SMS service for 2FA
- [ ] Set up backend API server
- [ ] Update `APIService.baseURL` with production URL
- [ ] Move password hashing to backend (use bcrypt/Argon2)
- [ ] Implement rate limiting on backend
- [ ] Test all authentication flows
- [ ] Perform security audit

## 🐛 Troubleshooting

### "API key not found" error in AI Chat
- Make sure you've set the OpenAI API key using `setOpenAIAPIKey()`
- Or set the `OPENAI_API_KEY` environment variable
- Check Keychain Access app (macOS) to verify key is stored

### 2FA code not working
- Check that code hasn't expired (10 minutes)
- Try resending code
- Verify code is 6 digits

### Can't log in with existing account
- Existing accounts have plain text passwords
- You'll need to create a new account (passwords are now hashed)
- Or update existing accounts to use hashed passwords

## 📚 Documentation

- **Full Security Guide**: See `API_SECURITY_GUIDE.md`
- **Quick Actions**: See `QUICK_SECURITY_ACTIONS.md`
- **Implementation Summary**: See `SECURITY_IMPLEMENTATION_SUMMARY.md`

## ✅ All Security Features Implemented!

Your app now has:
- ✅ Secure password hashing
- ✅ Keychain storage for sensitive data
- ✅ 2FA authentication
- ✅ Secure API key management
- ✅ API service layer ready for backend
- ✅ Token management
- ✅ Secure logout

You're ready to connect to a backend API when you're ready!
