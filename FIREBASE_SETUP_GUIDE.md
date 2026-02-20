# Firebase Setup Guide

## Quick Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Get Active"
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter iOS bundle ID: `Active.Get.Get-Active`
3. Register app
4. Download `GoogleService-Info.plist`
5. **Important**: Add `GoogleService-Info.plist` to your Xcode project:
   - Drag the file into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to target: "Get Active"

### 3. Install Firebase SDK

#### Option A: Swift Package Manager (Recommended)

1. In Xcode, go to **File → Add Packages...**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select these packages:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseStorage`
4. Click "Add Package"
5. Add to target: "Get Active"

#### Option B: CocoaPods

Add to your `Podfile`:
```ruby
pod 'FirebaseAuth'
pod 'FirebaseFirestore'
pod 'FirebaseStorage'
```

Then run: `pod install`

### 4. Initialize Firebase in Your App

The `FirebaseService` will automatically initialize Firebase when first accessed. Make sure `GoogleService-Info.plist` is in your project.

### 5. Enable Authentication Methods

1. In Firebase Console, go to **Authentication → Sign-in method**
2. Enable **Email/Password**
3. (Optional) Enable other providers (Google, Apple, etc.)

### 6. Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose a location (closest to your users)
5. Click "Enable"

### 7. Set Up Storage (for images)

1. In Firebase Console, go to **Storage**
2. Click "Get started"
3. Start in **test mode** (for development)
4. Choose a location
5. Click "Done"

### 8. Configure Security Rules

#### Firestore Rules (for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Events: authenticated users can read, creators can write
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.createdBy == request.auth.uid;
    }
  }
}
```

#### Storage Rules (for production):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
  }
}
```

### 9. Enable Firebase in Your App

The app is already configured to use Firebase! Just make sure:

1. `GoogleService-Info.plist` is in your project
2. Firebase SDK is installed
3. `useFirebase = true` in `AuthenticationManager.swift` (already set)

### 10. Test Firebase Connection

1. Run your app
2. Try signing up a new user
3. Check Firebase Console → Authentication to see the user
4. Check Firestore Database to see user document

## Troubleshooting

### "Firebase not initialized" error
- Make sure `GoogleService-Info.plist` is in your project
- Check that it's added to the target
- Verify the bundle ID matches

### "Permission denied" error
- Check Firestore security rules
- Make sure user is authenticated
- Verify rules allow the operation

### Images not uploading
- Check Storage security rules
- Verify Storage is enabled in Firebase Console
- Check file size limits

## Next Steps

1. **Set up email service** for 2FA (see Email Service Setup)
2. **Configure Firestore indexes** if needed for queries
3. **Set up production security rules** (replace test mode)
4. **Enable Firebase Analytics** (optional)
5. **Set up Firebase Cloud Messaging** for push notifications (optional)

## Production Checklist

- [ ] Replace test mode security rules with production rules
- [ ] Set up Firestore indexes for queries
- [ ] Configure Storage rules with proper limits
- [ ] Set up Firebase Cloud Messaging for push notifications
- [ ] Enable Firebase Analytics
- [ ] Set up backup and monitoring
- [ ] Configure billing alerts


## Quick Setup Steps

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Get Active"
4. Enable Google Analytics (optional)
5. Click "Create project"

### 2. Add iOS App to Firebase

1. In Firebase Console, click "Add app" → iOS
2. Enter iOS bundle ID: `Active.Get.Get-Active`
3. Register app
4. Download `GoogleService-Info.plist`
5. **Important**: Add `GoogleService-Info.plist` to your Xcode project:
   - Drag the file into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Add to target: "Get Active"

### 3. Install Firebase SDK

#### Option A: Swift Package Manager (Recommended)

1. In Xcode, go to **File → Add Packages...**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select these packages:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseStorage`
4. Click "Add Package"
5. Add to target: "Get Active"

#### Option B: CocoaPods

Add to your `Podfile`:
```ruby
pod 'FirebaseAuth'
pod 'FirebaseFirestore'
pod 'FirebaseStorage'
```

Then run: `pod install`

### 4. Initialize Firebase in Your App

The `FirebaseService` will automatically initialize Firebase when first accessed. Make sure `GoogleService-Info.plist` is in your project.

### 5. Enable Authentication Methods

1. In Firebase Console, go to **Authentication → Sign-in method**
2. Enable **Email/Password**
3. (Optional) Enable other providers (Google, Apple, etc.)

### 6. Set Up Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose a location (closest to your users)
5. Click "Enable"

### 7. Set Up Storage (for images)

1. In Firebase Console, go to **Storage**
2. Click "Get started"
3. Start in **test mode** (for development)
4. Choose a location
5. Click "Done"

### 8. Configure Security Rules

#### Firestore Rules (for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Events: authenticated users can read, creators can write
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.createdBy == request.auth.uid;
    }
  }
}
```

#### Storage Rules (for production):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
  }
}
```

### 9. Enable Firebase in Your App

The app is already configured to use Firebase! Just make sure:

1. `GoogleService-Info.plist` is in your project
2. Firebase SDK is installed
3. `useFirebase = true` in `AuthenticationManager.swift` (already set)

### 10. Test Firebase Connection

1. Run your app
2. Try signing up a new user
3. Check Firebase Console → Authentication to see the user
4. Check Firestore Database to see user document

## Troubleshooting

### "Firebase not initialized" error
- Make sure `GoogleService-Info.plist` is in your project
- Check that it's added to the target
- Verify the bundle ID matches

### "Permission denied" error
- Check Firestore security rules
- Make sure user is authenticated
- Verify rules allow the operation

### Images not uploading
- Check Storage security rules
- Verify Storage is enabled in Firebase Console
- Check file size limits

## Next Steps

1. **Set up email service** for 2FA (see Email Service Setup)
2. **Configure Firestore indexes** if needed for queries
3. **Set up production security rules** (replace test mode)
4. **Enable Firebase Analytics** (optional)
5. **Set up Firebase Cloud Messaging** for push notifications (optional)

## Production Checklist

- [ ] Replace test mode security rules with production rules
- [ ] Set up Firestore indexes for queries
- [ ] Configure Storage rules with proper limits
- [ ] Set up Firebase Cloud Messaging for push notifications
- [ ] Enable Firebase Analytics
- [ ] Set up backup and monitoring
- [ ] Configure billing alerts




