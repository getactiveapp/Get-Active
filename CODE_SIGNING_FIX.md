# Fixing Code Signing Error

The error "The identity used to sign the executable is no longer valid" typically occurs when:
1. Your development certificate has expired
2. Your provisioning profile is missing or expired
3. Your device doesn't trust your developer account

## Steps to Fix:

### 1. Clean Build Folder
- In Xcode: Product → Clean Build Folder (or press Shift+Cmd+K)
- Delete Derived Data (already done via script)

### 2. Check Your Apple Developer Account
- Open Xcode → Settings → Accounts
- Make sure your Apple ID is signed in
- Click "Download Manual Profiles" if needed
- If you see any expired certificates, you may need to refresh them

### 3. Update Signing Settings
- Select your project in Xcode
- Go to the "Signing & Capabilities" tab
- Make sure "Automatically manage signing" is checked
- Select your Team (G87DM5F89R)
- Xcode should automatically regenerate the provisioning profile

### 4. Trust Developer on Device
On your iPhone:
- Settings → General → VPN & Device Management (or Device Management)
- Find your developer certificate
- Tap "Trust [Your Name]"
- Confirm by tapping "Trust"

### 5. Restart Xcode and Rebuild
- Quit Xcode completely
- Reopen Xcode
- Try building and running again

## Alternative: Use Simulator
If you need to test immediately, you can run on the iOS Simulator instead of a physical device. The simulator doesn't require code signing.

## If Problem Persists:
1. Revoke and regenerate certificates in Apple Developer Portal
2. Remove and re-add your Apple ID in Xcode Settings
3. Check that your device UDID is registered in your developer account

