# Quick Start: Feature Flags

## Setup Your GitHub Repository (One-Time)

### Step 1: Create GitHub Repository
1. Go to GitHub and create a new repository (or use an existing one)
2. Make it **public** (or see advanced setup for private repos)

### Step 2: Add Feature Flags Folder and File
1. In your GitHub repository, create a folder named `FeatureFlags`
2. Inside that folder, create a file named `feature-flags.json`
3. Copy this content:
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
3. Commit and push the file to your repository

### Step 3: Configure in App
1. Open `Get Active/Managers/FeatureFlagsConfig.swift`
2. Update these values:
   ```swift
   static let githubUsername = "your-github-username"
   static let githubRepo = "your-repo-name"
   static let branch = "main"  // or "master"
   static let filePath = "FeatureFlags"  // Already set to use FeatureFlags folder!
   ```
3. Build and run the app

## Toggle Features (No Code Changes!)

### To Hide/Show Next Door:
1. Go to your GitHub repository
2. Navigate to the `FeatureFlags` folder
3. Edit the `feature-flags.json` file
4. Change `"next_door_enabled": false` to `true` (or vice versa)
5. Save and commit the file
6. Restart the app to see changes

### Example GitHub Setup:
- Username: `johndoe`
- Repo: `my-app-config`
- Branch: `main`
- Folder: `FeatureFlags/`
- File: `FeatureFlags/feature-flags.json`

**Config would be:**
```swift
static let githubUsername = "johndoe"
static let githubRepo = "my-app-config"
static let branch = "main"
static let filePath = "FeatureFlags"
```

**Resulting URL:** `https://raw.githubusercontent.com/johndoe/my-app-config/main/FeatureFlags/feature-flags.json`

## Current Default
Next Door is **HIDDEN by default** (`false`) until you enable it via GitHub config.

## No Code Changes Needed After Setup!
Just edit the JSON file in GitHub - the app will load it automatically!
