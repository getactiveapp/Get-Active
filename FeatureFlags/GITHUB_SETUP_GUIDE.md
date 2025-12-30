# GitHub Feature Flags Setup Guide

## 🚀 Quick Setup (3 Steps)

### Step 1: Create GitHub Repository
1. Go to [GitHub.com](https://github.com)
2. Click "New repository"
3. Name it (e.g., `get-active-config`)
4. Make it **Public** (or see private repo setup below)
5. Click "Create repository"

### Step 2: Add Feature Flags Folder and File
1. In your new repository, click "Add file" → "Create new file"
2. In the file path, type: `FeatureFlags/feature-flags.json` (this creates the folder automatically)
3. Copy and paste this content:
```json
{
  "next_door_enabled": false,
  "friend_finder_enabled": true,
  "map_enabled": true,
  "favorites_enabled": true,
  "analytics_enabled": true,
  "chatbot_enabled": true
}
```
4. Click "Commit new file"

### Step 3: Link in Your App
1. Open `Get Active/Managers/FeatureFlagsConfig.swift` in Xcode
2. Update these 4 lines:
   ```swift
   static let githubUsername = "YOUR_GITHUB_USERNAME"  // ← Your GitHub username
   static let githubRepo = "YOUR_REPO_NAME"        // ← Your repo name
   static let branch = "main"                      // ← Usually "main" or "master"
   static let filePath = "FeatureFlags"           // ← Already set to use FeatureFlags folder!
   ```

**Example:**
```swift
static let githubUsername = "johndoe"
static let githubRepo = "get-active-config"
static let branch = "main"
static let filePath = "FeatureFlags"  // Uses FeatureFlags/feature-flags.json
```

4. Build and run your app
5. The app will automatically load flags from GitHub!

## ✅ How to Toggle Features

### Hide Next Door:
1. Go to your GitHub repository
2. Click on `feature-flags.json`
3. Click the pencil icon (✏️) to edit
4. Change: `"next_door_enabled": false`
5. Click "Commit changes"
6. Restart your app

### Show Next Door:
1. Same steps as above
2. Change: `"next_door_enabled": true`
3. Commit and restart app

## 📋 Complete Example

**GitHub Repository:**
- URL: `https://github.com/johndoe/get-active-config`
- Folder: `FeatureFlags/`
- File: `FeatureFlags/feature-flags.json`

**Config File (`FeatureFlagsConfig.swift`):**
```swift
static let githubUsername = "johndoe"
static let githubRepo = "get-active-config"
static let branch = "main"
static let filePath = "FeatureFlags"
```

**Result:**
- App loads from: `https://raw.githubusercontent.com/johndoe/get-active-config/main/FeatureFlags/feature-flags.json`

## 🔒 Private Repository Setup

If you want to use a private repository:

1. Create a GitHub Personal Access Token:
   - Go to GitHub Settings → Developer settings → Personal access tokens
   - Generate token with `repo` scope
   - Copy the token

2. Update the URL format in `FeatureFlagsConfig.swift`:
   ```swift
   static var remoteConfigURL: String {
       let token = "YOUR_TOKEN_HERE"
       let path = filePath.isEmpty ? "feature-flags.json" : "\(filePath)/feature-flags.json"
       return "https://\(token)@raw.githubusercontent.com/\(githubUsername)/\(githubRepo)/\(branch)/\(path)"
   }
   ```

**⚠️ Note:** This exposes the token in your code. For production apps, consider using a backend service.

## 🧪 Testing

1. **Test the URL:** Open the raw URL in a browser to verify it works:
   ```
   https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/FeatureFlags/feature-flags.json
   ```

2. **Check App Logs:** If flags don't load, check Xcode console for errors

3. **Fallback:** If GitHub is unavailable, the app uses default flags (Next Door hidden)

## 📝 Feature Flags Reference

| Flag | Controls | Default |
|------|----------|---------|
| `next_door_enabled` | Next Door tab visibility | `false` (hidden) |
| `friend_finder_enabled` | Friend Finder tab | `true` (shown) |
| `map_enabled` | Map tab | `true` (shown) |
| `favorites_enabled` | Favorites tab | `true` (shown) |
| `analytics_enabled` | Analytics features | `true` (enabled) |
| `chatbot_enabled` | Chatbot features | `true` (enabled) |

## 🎯 Benefits

✅ **No Code Changes** - Toggle features by editing JSON in GitHub  
✅ **Instant Updates** - Changes take effect after app restart  
✅ **Version Control** - Track all feature flag changes in Git  
✅ **Team Collaboration** - Multiple people can manage flags  
✅ **Safe Fallback** - App works even if GitHub is down  

## 🆘 Troubleshooting

**Flags not loading?**
- Check your internet connection
- Verify the GitHub URL is correct (test in browser)
- Make sure the repository is public (or token is set for private)
- Check Xcode console for error messages

**Feature still showing?**
- Make sure you restarted the app
- Verify the JSON syntax is correct
- Check that the flag name matches exactly (case-sensitive)
