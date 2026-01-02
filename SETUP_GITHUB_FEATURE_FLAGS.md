# Setup GitHub Feature Flags - Complete Guide

## 🚀 Quick Setup (5 Steps)

### Step 1: Create GitHub Repository

1. Go to https://github.com and sign in
2. Click the **"+"** button (top right) → **"New repository"**
3. Fill in:
   - **Repository name**: `get-active-feature-flags` (or any name)
   - **Visibility**: Public (recommended) or Private
   - ✅ Check **"Add a README file"**
4. Click **"Create repository"**

### Step 2: Add Feature Flags File

1. In your new repository, click **"Add file"** → **"Create new file"**
2. **File name**: `feature-flags.json`
3. **File content** (copy and paste):
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
4. Scroll down, click **"Commit new file"**

### Step 3: Get Your GitHub Username

1. Click your profile picture (top right on GitHub)
2. Your username is shown in the dropdown (e.g., `johndoe`)

### Step 4: Update App Configuration

1. Open Xcode
2. Navigate to: `Get Active/Config/FeatureFlagsConfig.swift`
3. Update these three values:

```swift
struct FeatureFlagsConfig {
    // Replace with your GitHub username
    static let githubUsername = "YOUR_USERNAME"  // ← Change this
    
    // Replace with your repository name
    static let repositoryName = "YOUR_REPO"      // ← Change this
    
    // Usually "main" (or "master" for older repos)
    static let branchName = "main"               // ← Usually "main"
    
    // File name (don't change this)
    static let fileName = "feature-flags.json"
}
```

**Example:**
If your username is `techsgivingsummit` and repo is `get-active-feature-flags`:
```swift
static let githubUsername = "techsgivingsummit"
static let repositoryName = "get-active-feature-flags"
static let branchName = "main"
```

### Step 5: Test It

1. Build and run your app
2. The app will automatically load flags from GitHub
3. Next Door should be hidden (since it's set to `false`)

## ✅ How to Toggle Features

### To Show/Hide Next Door:

1. Go to your GitHub repository
2. Click on `feature-flags.json`
3. Click the **pencil icon** (✏️ Edit)
4. Change the value:
   ```json
   "next_door_enabled": true   // Show Next Door
   "next_door_enabled": false  // Hide Next Door
   ```
5. Scroll down, click **"Commit changes"**
6. **Restart your app** to see changes

## 📋 Complete Example

**Your GitHub Setup:**
- Username: `techsgivingsummit`
- Repository: `get-active-feature-flags`
- Branch: `main`
- File: `feature-flags.json`

**Your Config File Should Look Like:**
```swift
static let githubUsername = "techsgivingsummit"
static let repositoryName = "get-active-feature-flags"
static let branchName = "main"
```

**Your GitHub File URL Will Be:**
```
https://raw.githubusercontent.com/techsgivingsummit/get-active-feature-flags/main/feature-flags.json
```

## 🔍 Verify Your Setup

1. After updating `FeatureFlagsConfig.swift`, the app will automatically use your GitHub URL
2. To verify it's working:
   - Open the URL in a browser (should show the JSON file)
   - Check that the JSON is valid
   - Restart the app

## 🎯 Current Status

- ✅ Feature flag system installed
- ✅ Configuration file created at `Get Active/Config/FeatureFlagsConfig.swift`
- ⏳ **You need to**: Update the 3 values in `FeatureFlagsConfig.swift` with your GitHub info

## 💡 Pro Tips

1. **Keep it simple**: Use a public repository for easiest setup
2. **Test locally first**: The app uses defaults if GitHub isn't configured
3. **Version control**: Commit your `FeatureFlagsConfig.swift` with placeholder values, then update with your actual GitHub info
4. **Multiple environments**: You can create different branches (dev, staging, prod) with different flag values

## 🆘 Troubleshooting

**"Flags not loading"**
- Check your internet connection
- Verify the URL works in a browser
- Make sure repository is public (or use token for private)

**"Next Door still showing"**
- Make sure you set `"next_door_enabled": false` in GitHub
- Restart the app completely
- Check that `FeatureFlagsConfig.swift` has correct values

**"Want to test without GitHub?"**
- Just leave the placeholder values (`YOUR_USERNAME`, `YOUR_REPO`)
- The app will use default flags (Next Door hidden)

---

**That's it!** Once you update `FeatureFlagsConfig.swift` with your GitHub details, you can control features remotely from GitHub. 🎉
