# Feature Flags Setup Guide

This app uses a remote feature flag system that allows you to toggle features on/off without code changes. The flags are loaded from a GitHub repository.

## Quick Start

### 1. Create a GitHub Repository (if you don't have one)

1. Go to GitHub and create a new repository (or use an existing one)
2. Make it public (or use GitHub tokens for private repos - see Advanced section)

### 2. Add the Feature Flags File

1. In your GitHub repository, create a file named `feature-flags.json` in the root directory
2. Copy the contents from the `feature-flags.json` file in this project
3. Commit and push the file to your repository

### 3. Update the Remote URL

1. Open `Get Active/Managers/FeatureFlagsManager.swift`
2. Find the line: `private let remoteConfigURL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/feature-flags.json"`
3. Replace with your actual GitHub URL:
   - Format: `https://raw.githubusercontent.com/USERNAME/REPO_NAME/BRANCH/feature-flags.json`
   - Example: `https://raw.githubusercontent.com/johndoe/get-active-app/main/feature-flags.json`

### 4. Toggle Features

Simply edit the `feature-flags.json` file in your GitHub repository:

```json
{
  "next_door_enabled": false,    // Set to false to hide Next Door tab
  "friend_finder_enabled": true,
  "map_enabled": true,
  "favorites_enabled": true,
  "analytics_enabled": true,
  "chatbot_enabled": true
}
```

**To hide Next Door:** Set `"next_door_enabled": false`  
**To show Next Door:** Set `"next_door_enabled": true`

After updating the file in GitHub, the app will automatically load the new flags when:
- The app is restarted
- The app comes to foreground (if you add pull-to-refresh)
- You manually refresh (if you add a refresh button)

## Feature Flags Reference

| Flag | Description | Default |
|------|-------------|---------|
| `next_door_enabled` | Shows/hides the "Next Door" tab | `false` |
| `friend_finder_enabled` | Shows/hides the "Friend Finder" tab | `true` |
| `map_enabled` | Shows/hides the "Map" tab | `true` |
| `favorites_enabled` | Shows/hides the "Favorites" tab | `true` |
| `analytics_enabled` | Enables/disables analytics features | `true` |
| `chatbot_enabled` | Enables/disables chatbot features | `true` |

## How It Works

1. **Remote First**: The app tries to load flags from your GitHub repository
2. **Local Fallback**: If the remote load fails, it uses cached local flags or defaults
3. **Automatic Caching**: Successfully loaded remote flags are cached locally
4. **No Code Changes**: Toggle features by editing the JSON file in GitHub

## Testing Locally

To test without GitHub:

1. The app will use default flags if remote loading fails
2. You can modify the default flags in `FeatureFlagsManager.swift`:
   ```swift
   static let `default` = FeatureFlags(
       nextDoorEnabled: false, // Change this
       // ...
   )
   ```

## Advanced: Private Repository

If you want to use a private GitHub repository:

1. Create a GitHub Personal Access Token with `repo` scope
2. Update the URL format:
   ```
   https://TOKEN@raw.githubusercontent.com/USERNAME/REPO/BRANCH/feature-flags.json
   ```
3. **Note**: This exposes the token in the app. For production, consider using a backend service.

## Troubleshooting

### Flags not updating?
- Check your internet connection
- Verify the GitHub URL is correct
- Check that the file is accessible (try opening the raw URL in a browser)
- The app caches flags locally - restart the app to force a refresh

### Feature still showing after disabling?
- Make sure you updated the correct flag name
- Restart the app
- Check the JSON syntax is valid

## Example GitHub Setup

1. Repository: `my-app-config`
2. Branch: `main`
3. File path: `feature-flags.json`
4. URL: `https://raw.githubusercontent.com/yourusername/my-app-config/main/feature-flags.json`

## Adding New Feature Flags

1. Add the property to `FeatureFlags` struct in `FeatureFlagsManager.swift`
2. Add it to the `default` flags
3. Add it to the JSON file in GitHub
4. Use it in your code: `featureFlags.flags.yourNewFlag`
