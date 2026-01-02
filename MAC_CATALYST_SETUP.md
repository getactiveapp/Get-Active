# Mac Catalyst Setup Guide

This guide explains how to enable Mac Catalyst support so the Get Active app can run on MacBooks.

## Current Status

- ✅ **iPad Support**: Already enabled (TARGETED_DEVICE_FAMILY = "1,2")
- 🔧 **Mac Catalyst**: Needs to be enabled in Xcode

## Steps to Enable Mac Catalyst

### Method 1: Via Xcode UI (Recommended)

1. **Open the project in Xcode**
   - Open `Get Active.xcodeproj` in Xcode

2. **Select the Target**
   - Click on the "Get Active" project in the navigator
   - Select the "Get Active" target under "TARGETS"

3. **Enable Mac Catalyst**
   - Go to the **"General"** tab
   - Under **"Deployment Info"**, check the **"Mac"** checkbox
   - Xcode will automatically configure Mac Catalyst settings

4. **Configure Signing** (if needed)
   - Go to **"Signing & Capabilities"** tab
   - Ensure your Team is selected
   - Xcode will handle the rest automatically

5. **Build and Run**
   - Select "My Mac (Designed for iPad)" as the destination
   - Build and run the app

### Method 2: Verify Project Settings

The project should have these settings configured:

```
SUPPORTS_MACCATALYST = YES
SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD = YES
TARGETED_DEVICE_FAMILY = "1,2"
```

## What Happens When Enabled

- The app will appear in the Mac App Store (if published)
- Users can run the iOS app on their Mac
- The UI automatically adapts to Mac's larger screens
- Keyboard and mouse interactions are supported

## Testing

1. **On iPad**: Test in portrait and landscape orientations
2. **On Mac**: Test window resizing, keyboard navigation, and mouse interactions

## Notes

- Mac Catalyst uses your existing iOS codebase
- Most UIKit/SwiftUI code works automatically
- Some iOS-specific features may need adjustments
- The app will use macOS-style controls when appropriate

## Troubleshooting

If you encounter issues:

1. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
2. **Delete Derived Data**: Remove `~/Library/Developer/Xcode/DerivedData/Get_Active-*`
3. **Restart Xcode**: Quit and reopen Xcode
4. **Check Signing**: Ensure your development team is correctly configured

