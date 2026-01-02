# GitHub Feature Flags Setup - Step by Step

## Quick Setup (5 minutes)

### Step 1: Create GitHub Repository for Config

1. Go to [GitHub.com](https://github.com) and sign in
2. Click the **"+"** icon in the top right → **"New repository"**
3. Name it: `get-active-feature-flags` (or any name you prefer)
4. Make it **Public** (or Private if you want - see advanced section)
5. Check **"Add a README file"**
6. Click **"Create repository"**

### Step 2: Add the Feature Flags File

1. In your new repository, click **"Add file"** → **"Create new file"**
2. Name the file: `feature-flags.json`
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

4. Scroll down and click **"Commit new file"**

### Step 3: Get Your Raw URL

1. In your repository, click on the `feature-flags.json` file
2. Click the **"Raw"** button (top right of the file view)
3. Copy the URL from your browser's address bar
   - It will look like: `https://raw.githubusercontent.com/YOUR_USERNAME/get-active-feature-flags/main/feature-flags.json`

### Step 4: Update the App Code

1. Open `Get Active/Managers/FeatureFlagsManager.swift` in Xcode
2. Find this line (around line 41):
   ```swift
   private let remoteConfigURL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/feature-flags.json"
   ```
3. Replace it with your actual URL from Step 3
4. Save the file

### Step 5: Test It

1. Build and run your app
2. The Next Door tab should be hidden (since it's set to `false`)
3. To test: Edit the file in GitHub, change `"next_door_enabled": true`, save, restart app

## Example

If your GitHub username is `johndoe` and your repo is `get-active-feature-flags`:

**Your URL would be:**
```
https://raw.githubusercontent.com/johndoe/get-active-feature-flags/main/feature-flags.json
```

**Update this line in FeatureFlagsManager.swift:**
```swift
private let remoteConfigURL = "https://raw.githubusercontent.com/johndoe/get-active-feature-flags/main/feature-flags.json"
```

## How to Toggle Features

1. Go to your GitHub repository
2. Click on `feature-flags.json`
3. Click the **pencil icon** (Edit)
4. Change the values:
   - `"next_door_enabled": false` → Hide Next Door
   - `"next_door_enabled": true` → Show Next Door
5. Scroll down, add a commit message (optional)
6. Click **"Commit changes"**
7. Restart your app to see the changes

## Troubleshooting

**App not loading flags?**
- Check your internet connection
- Verify the URL is correct (try opening it in a browser)
- Make sure the repository is public (or use token for private - see below)

**Want to use a Private Repository?**
- Create a GitHub Personal Access Token
- Update the URL to: `https://TOKEN@raw.githubusercontent.com/USERNAME/REPO/BRANCH/feature-flags.json`
- ⚠️ Note: This exposes the token in your code. For production, consider a backend service.

## Current Status

✅ Feature flag system is ready
✅ Next Door is hidden by default
⏳ Waiting for you to add your GitHub URL

Once you add your GitHub URL, you can control all features remotely!
