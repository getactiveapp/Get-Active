# Complete Firebase Setup Guide

## ✅ What's Already Done

- ✅ Firebase code is integrated
- ✅ Events will sync to Firebase automatically
- ✅ Messages will use Firebase Firestore
- ✅ Authentication uses Firebase
- ✅ Image uploads use Firebase Storage

## 🚀 Setup Steps (30 minutes)

### Step 1: Create Firebase Project (5 min)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: **"Get Active"**
4. Enable Google Analytics (optional - recommended)
5. Click **"Create project"**
6. Wait for project creation (30 seconds)

### Step 2: Add iOS App to Firebase (5 min)

1. In Firebase Console, click **"Add app"** → Select **iOS** (Apple icon)
2. Enter iOS bundle ID: `Active.Get.Get-Active`
   - This must match your Xcode project bundle ID exactly
3. Click **"Register app"**
4. **Download `GoogleService-Info.plist`**
5. **Important**: You already have this file! Just verify it's in your Xcode project:
   - Open Xcode
   - Check that `GoogleService-Info.plist` is in your project navigator
   - If not, drag it into the "Get Active" folder in Xcode
   - Make sure "Copy items if needed" is checked
   - Add to target: "Get Active"

### Step 3: Enable Authentication (2 min)

1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click **"Get started"** (if first time)
3. Go to **"Sign-in method"** tab
4. Click on **"Email/Password"**
5. Enable it (toggle ON)
6. Click **"Save"**

### Step 4: Create Firestore Database (5 min)

1. In Firebase Console, go to **Firestore Database** (left sidebar)
2. Click **"Create database"**
3. Select **"Start in test mode"** (for development)
   - ⚠️ **Important**: Update security rules before production!
4. Choose a location (closest to your users)
   - Recommended: `us-central1` or closest to your region
5. Click **"Enable"**
6. Wait for database creation (30 seconds)

### Step 5: Create Storage (3 min)

1. In Firebase Console, go to **Storage** (left sidebar)
2. Click **"Get started"**
3. Select **"Start in test mode"** (for development)
4. Choose same location as Firestore
5. Click **"Done"**

### Step 6: Set Up Firestore Indexes (5 min)

Firestore needs indexes for some queries. Create these:

1. Go to **Firestore Database** → **Indexes** tab
2. Click **"Create Index"**
3. Create index for conversations:
   - Collection ID: `conversations`
   - Fields to index:
     - `participants` (Array)
     - `lastMessageTimestamp` (Descending)
   - Query scope: Collection
   - Click **"Create"**

### Step 7: Verify Setup (5 min)

1. **Check `GoogleService-Info.plist`** is in your Xcode project
2. **Build the app** (`⌘B`) - should compile without errors
3. **Run the app**
4. **Try signing up** a new user
5. **Check Firebase Console**:
   - Authentication → Should see your user
   - Firestore Database → Should see `users` collection with your user document
6. **Try creating an event**
7. **Check Firestore** → Should see `events` collection

## ✅ Verification Checklist

After setup, verify:

- [ ] Firebase project created
- [ ] iOS app added to Firebase
- [ ] `GoogleService-Info.plist` in Xcode project
- [ ] Email/Password authentication enabled
- [ ] Firestore database created
- [ ] Storage created
- [ ] App builds without errors
- [ ] Can sign up a user (check Firebase Console)
- [ ] Can create an event (check Firestore)
- [ ] Events appear in Firestore `events` collection

## 🔒 Security Rules (Important for Production!)

### Firestore Rules (Update before production):

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
    
    // Conversations: only participants can read/write
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read, write: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
      }
    }
  }
}
```

### Storage Rules (Update before production):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /events/{eventId}/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
  }
}
```

## 🧪 Testing

### Test Authentication:
1. Sign up a new user
2. Check Firebase Console → Authentication
3. Should see the user listed

### Test Events:
1. Create an event in the app
2. Check Firebase Console → Firestore Database
3. Should see `events` collection with your event

### Test Messages:
1. Start a conversation with a friend
2. Send a message
3. Check Firestore → `conversations` collection
4. Should see conversation and messages

## 🐛 Troubleshooting

### "Firebase not initialized"
- Make sure `GoogleService-Info.plist` is in your Xcode project
- Check it's added to the target
- Verify bundle ID matches

### "Permission denied" in Firestore
- Check you're using test mode (allows reads/writes)
- Or update security rules to allow your operations

### Events not appearing
- Check Firestore console for errors
- Verify `useFirebase = true` in EventManager
- Check console logs for Firebase errors

### Messages not working
- Verify Firestore database is created
- Check conversations collection exists
- Verify user is authenticated

## 📝 Next Steps After Setup

1. ✅ Test all features
2. ✅ Update security rules (before production)
3. ✅ Set up production Firebase project (separate from dev)
4. ✅ Configure billing alerts
5. ✅ Set up monitoring

## 🎉 You're Done!

Once you complete these steps:
- ✅ Events will sync to Firebase
- ✅ Messages will work in real-time
- ✅ User data will be stored in Firestore
- ✅ Images will upload to Storage
- ✅ Everything will sync across devices!

Your app is now fully connected to Firebase! 🚀
