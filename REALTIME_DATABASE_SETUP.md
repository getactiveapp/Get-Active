# Realtime Database Setup Instructions

This project now uses both **Firestore** (for main data) and **Realtime Database** (for presence and live updates).

## Adding FirebaseDatabase Package to Xcode

Since the project uses Swift Package Manager, you need to add FirebaseDatabase manually:

### Steps:

1. **Open Xcode** and select your project file
2. **Select the "Get Active" target**
3. Go to **"Package Dependencies"** tab
4. Click the **"+"** button to add a package
5. Enter this URL: `https://github.com/firebase/firebase-ios-sdk`
6. Click **"Add Package"**
7. Select **"FirebaseDatabase"** from the list of products
8. Click **"Add Package"**

Alternatively, if the firebase-ios-sdk package is already added:
1. Select your project in Xcode
2. Select the "Get Active" target
3. Go to **"General"** → **"Frameworks, Libraries, and Embedded Content"**
4. Click **"+"** 
5. Search for "FirebaseDatabase"
6. Add it

## What Realtime Database is Used For

### 1. **Presence/Online Status**
- Tracks when users are online/offline
- Updates automatically when users log in/out
- Used in:
  - Data Dashboard (shows online status)
  - Friend profiles (shows if friend is online)
  - User search results (shows online status)

### 2. **Live Event Updates** (Future)
- Real-time like counts
- Real-time attendee counts
- Live event metrics

### 3. **Typing Indicators** (Future)
- Shows when users are typing in conversations
- Real-time chat indicators

## Database Structure

### Presence Data
```
presence/
  {userId}/
    status: "online" | "offline"
    lastSeen: timestamp
    timestamp: timestamp
```

### Live Event Updates (Future)
```
events_live/
  {eventId}/
    likes: number
    attendees: number
    views: number
```

### Typing Indicators (Future)
```
typing/
  {conversationId}/
    {userId}: true/false
```

## Realtime Database Rules

Add these security rules to your Firebase Realtime Database:

```json
{
  "rules": {
    "presence": {
      "$userId": {
        ".read": "auth != null",
        ".write": "$userId === auth.uid || root.child('presence').child(auth.uid).child('status').val() === 'online'",
        "status": {
          ".validate": "newData.isString() && (newData.val() === 'online' || newData.val() === 'offline')"
        },
        "lastSeen": {
          ".validate": "newData.isNumber()"
        }
      }
    },
    "events_live": {
      "$eventId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "typing": {
      "$conversationId": {
        "$userId": {
          ".read": "auth != null && ($userId === auth.uid || root.child('conversations').child($conversationId).child('participants').hasChild(auth.uid))",
          ".write": "$userId === auth.uid"
        }
      }
    }
  }
}
```

## Testing

After adding the package:
1. Clean build folder (Cmd+Shift+K)
2. Build the project (Cmd+B)
3. The app will automatically:
   - Set users online when they log in
   - Set users offline when they log out
   - Show online status in the Data Dashboard

## Troubleshooting

If you see import errors:
- Make sure FirebaseDatabase is added to the target
- Clean build folder and rebuild
- Check that the package is resolved correctly

If online status doesn't work:
- Check Realtime Database rules are set correctly
- Verify the database exists in Firebase Console
- Check console logs for errors

