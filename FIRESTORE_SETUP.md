# Firestore Database Setup Instructions

## Error Message
If you see this error:
```
WatchStream Stream error: 'Not found: The database (default) does not exist for project get-active-99ab7'
```

## Solution

You need to create the Firestore database in your Firebase project. Follow these steps:

### Step 1: Open Firebase Console
Go to: https://console.cloud.google.com/firestore/databases?project=get-active-99ab7

Or navigate manually:
1. Go to https://console.firebase.google.com/
2. Select your project: **get-active-99ab7**
3. Click on **Firestore Database** in the left sidebar

### Step 2: Create Database
1. Click the **"Create Database"** button
2. Choose your database mode:
   - **Production mode**: More secure, requires security rules (recommended for production)
   - **Test mode**: Open access for 30 days (good for development/testing)

### Step 3: Select Location
1. Choose a location for your database (preferably close to your users)
2. Common choices:
   - `us-central` (Iowa) - Good for US-based apps
   - `europe-west` - Good for European users
   - `asia-southeast1` - Good for Asian users

### Step 4: Enable
1. Click **"Enable"**
2. Wait for the database to be created (usually takes 1-2 minutes)

### Step 5: Set Up Security Rules (Important!)

After creating the database, you MUST set up security rules:

1. Go to **Firestore Database** > **Rules** tab
2. Replace the default rules with these (for test mode):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null; // Users can read other users
    }
    
    // Events can be read by authenticated users, written by creators
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.creatorId == request.auth.uid;
    }
    
    // Messages/Conversations
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in resource.data.participants;
    }
    
    match /conversations/{conversationId}/messages/{messageId} {
      allow read, write: if request.auth != null && 
        request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
    }
  }
}
```

3. Click **"Publish"**

### Step 6: Restart Your App
After creating the database:
1. Close your Xcode app
2. Rebuild and run the app
3. The error should be gone!

## Alternative: Use Local Storage Mode

If you can't set up Firestore right now, the app will attempt to fall back to local storage mode. However, data won't sync across devices.

## Need Help?

- Firebase Documentation: https://firebase.google.com/docs/firestore/quickstart
- Firebase Console: https://console.firebase.google.com/

