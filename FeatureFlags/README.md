# Feature Flags

This folder contains all feature flag configuration and documentation.

## 📁 Folder Structure

```
FeatureFlags/
├── feature-flags.json          # Template JSON file for GitHub
├── README.md                    # This file
├── FEATURE_FLAGS_SETUP.md      # Complete setup guide
├── QUICK_START_FEATURE_FLAGS.md # Quick reference
└── GITHUB_SETUP_GUIDE.md       # GitHub setup instructions
```

## 🚀 Quick Setup

### 1. Create GitHub Repository
Create a new repository on GitHub (or use an existing one).

### 2. Create FeatureFlags Folder in GitHub
1. In your GitHub repository, create a folder named `FeatureFlags`
2. Add the `feature-flags.json` file inside this folder
3. Copy the content from `feature-flags.json` in this folder

### 3. Configure App
Open `Get Active/Managers/FeatureFlagsConfig.swift` and update:
```swift
static let githubUsername = "your-username"
static let githubRepo = "your-repo-name"
static let branch = "main"
static let filePath = "FeatureFlags"  // ← Already set to use FeatureFlags folder!
```

### 4. GitHub Repository Structure
Your GitHub repo should look like:
```
your-repo/
└── FeatureFlags/
    └── feature-flags.json
```

## ✅ Toggle Features

Edit `FeatureFlags/feature-flags.json` in your GitHub repository:
- Change `"next_door_enabled": false` to `true` to show Next Door
- Change `"next_door_enabled": true` to `false` to hide Next Door
- Commit and push changes
- Restart the app

## 📝 Current Configuration

The app is configured to load from:
```
https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/FeatureFlags/feature-flags.json
```

## 📚 Documentation

- **FEATURE_FLAGS_SETUP.md** - Complete setup instructions
- **QUICK_START_FEATURE_FLAGS.md** - Quick reference guide
- **GITHUB_SETUP_GUIDE.md** - Detailed GitHub setup
