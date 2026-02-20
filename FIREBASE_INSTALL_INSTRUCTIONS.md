# Firebase Installation Instructions

## Quick Fix: Install Firebase SDK

The Firebase SDK needs to be installed via Swift Package Manager. Here's how:

### Method 1: Via Xcode (Recommended)

1. **Open your project in Xcode**
   - Open `Get Active.xcodeproj`

2. **Add Firebase Package:**
   - In Xcode, go to **File → Add Packages...** (or press `⌘⇧K`)
   - In the search box, enter: `https://github.com/firebase/firebase-ios-sdk`
   - Click **Add Package**

3. **Select Required Modules:**
   - When prompted, select these packages:
     - ✅ **FirebaseAuth** (for authentication)
     - ✅ **FirebaseFirestore** (for database)
     - ✅ **FirebaseStorage** (for file storage)
   - Make sure **Add to Target: "Get Active"** is selected
   - Click **Add Package**

4. **Wait for Download:**
   - Xcode will download and integrate the packages
   - This may take a minute or two

5. **Build the Project:**
   - Press `⌘B` to build
   - The error should be resolved!

### Method 2: Manual Package Resolution

If Method 1 doesn't work:

1. **Open Package Dependencies:**
   - In Xcode, select your project in the navigator
   - Select the "Get Active" target
   - Go to **Package Dependencies** tab

2. **Add Package:**
   - Click the **+** button
   - Enter: `https://github.com/firebase/firebase-ios-sdk`
   - Click **Add Package**

3. **Select Modules:**
   - Select: FirebaseAuth, FirebaseFirestore, FirebaseStorage
   - Click **Add Package**

### Method 3: If Packages Are Already Added

If the packages show in Package Dependencies but still error:

1. **Clean Build Folder:**
   - Press `⌘⇧K` (Product → Clean Build Folder)

2. **Reset Package Caches:**
   - File → Packages → Reset Package Caches

3. **Resolve Packages:**
   - File → Packages → Resolve Package Versions

4. **Build Again:**
   - Press `⌘B`

## Verify Installation

After installation, you should see:
- ✅ No compilation errors
- ✅ Firebase modules available in imports
- ✅ Package.resolved file updated

## Troubleshooting

### "No such module 'FirebaseCore'"
- Make sure you added **FirebaseAuth**, **FirebaseFirestore**, and **FirebaseStorage**
- FirebaseCore is included automatically with these packages
- Try cleaning build folder (`⌘⇧K`)

### "Package resolution failed"
- Check your internet connection
- Try: File → Packages → Reset Package Caches
- Then: File → Packages → Resolve Package Versions

### "Cannot find 'Firebase' in scope"
- Make sure packages are added to the correct target
- Check that "Get Active" target is selected
- Rebuild the project

## Next Steps

Once Firebase is installed:
1. ✅ Make sure `GoogleService-Info.plist` is in your project
2. ✅ Build and run the app
3. ✅ Test Firebase authentication

## Alternative: Use CocoaPods (If SPM doesn't work)

If Swift Package Manager doesn't work, you can use CocoaPods:

1. **Install CocoaPods:**
   ```bash
   sudo gem install cocoapods
   ```

2. **Create Podfile:**
   ```bash
   cd "/Users/techsgivingsummit/Downloads/Get Active"
   pod init
   ```

3. **Edit Podfile:**
   ```ruby
   platform :ios, '18.2'
   
   target 'Get Active' do
     use_frameworks!
     
     pod 'FirebaseAuth'
     pod 'FirebaseFirestore'
     pod 'FirebaseStorage'
   end
   ```

4. **Install:**
   ```bash
   pod install
   ```

5. **Open workspace:**
   - Open `Get Active.xcworkspace` (not .xcodeproj)


## Quick Fix: Install Firebase SDK

The Firebase SDK needs to be installed via Swift Package Manager. Here's how:

### Method 1: Via Xcode (Recommended)

1. **Open your project in Xcode**
   - Open `Get Active.xcodeproj`

2. **Add Firebase Package:**
   - In Xcode, go to **File → Add Packages...** (or press `⌘⇧K`)
   - In the search box, enter: `https://github.com/firebase/firebase-ios-sdk`
   - Click **Add Package**

3. **Select Required Modules:**
   - When prompted, select these packages:
     - ✅ **FirebaseAuth** (for authentication)
     - ✅ **FirebaseFirestore** (for database)
     - ✅ **FirebaseStorage** (for file storage)
   - Make sure **Add to Target: "Get Active"** is selected
   - Click **Add Package**

4. **Wait for Download:**
   - Xcode will download and integrate the packages
   - This may take a minute or two

5. **Build the Project:**
   - Press `⌘B` to build
   - The error should be resolved!

### Method 2: Manual Package Resolution

If Method 1 doesn't work:

1. **Open Package Dependencies:**
   - In Xcode, select your project in the navigator
   - Select the "Get Active" target
   - Go to **Package Dependencies** tab

2. **Add Package:**
   - Click the **+** button
   - Enter: `https://github.com/firebase/firebase-ios-sdk`
   - Click **Add Package**

3. **Select Modules:**
   - Select: FirebaseAuth, FirebaseFirestore, FirebaseStorage
   - Click **Add Package**

### Method 3: If Packages Are Already Added

If the packages show in Package Dependencies but still error:

1. **Clean Build Folder:**
   - Press `⌘⇧K` (Product → Clean Build Folder)

2. **Reset Package Caches:**
   - File → Packages → Reset Package Caches

3. **Resolve Packages:**
   - File → Packages → Resolve Package Versions

4. **Build Again:**
   - Press `⌘B`

## Verify Installation

After installation, you should see:
- ✅ No compilation errors
- ✅ Firebase modules available in imports
- ✅ Package.resolved file updated

## Troubleshooting

### "No such module 'FirebaseCore'"
- Make sure you added **FirebaseAuth**, **FirebaseFirestore**, and **FirebaseStorage**
- FirebaseCore is included automatically with these packages
- Try cleaning build folder (`⌘⇧K`)

### "Package resolution failed"
- Check your internet connection
- Try: File → Packages → Reset Package Caches
- Then: File → Packages → Resolve Package Versions

### "Cannot find 'Firebase' in scope"
- Make sure packages are added to the correct target
- Check that "Get Active" target is selected
- Rebuild the project

## Next Steps

Once Firebase is installed:
1. ✅ Make sure `GoogleService-Info.plist` is in your project
2. ✅ Build and run the app
3. ✅ Test Firebase authentication

## Alternative: Use CocoaPods (If SPM doesn't work)

If Swift Package Manager doesn't work, you can use CocoaPods:

1. **Install CocoaPods:**
   ```bash
   sudo gem install cocoapods
   ```

2. **Create Podfile:**
   ```bash
   cd "/Users/techsgivingsummit/Downloads/Get Active"
   pod init
   ```

3. **Edit Podfile:**
   ```ruby
   platform :ios, '18.2'
   
   target 'Get Active' do
     use_frameworks!
     
     pod 'FirebaseAuth'
     pod 'FirebaseFirestore'
     pod 'FirebaseStorage'
   end
   ```

4. **Install:**
   ```bash
   pod install
   ```

5. **Open workspace:**
   - Open `Get Active.xcworkspace` (not .xcodeproj)




