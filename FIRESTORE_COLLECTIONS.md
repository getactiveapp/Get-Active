# Firestore Collections Structure

This document describes the Firestore database collections used by the Get Active app.

## Collections Overview

The app uses the following Firestore collections:

1. **`users`** - User profiles and account information
2. **`events`** - Event posts created by users
3. **`conversations`** - Chat conversations between users
   - **`messages`** (subcollection) - Individual messages in each conversation

---

## 1. `users` Collection

Stores user profile information and account details.

### Document Structure:
```javascript
{
  id: "user_id",              // Firebase Auth UID (document ID)
  username: "johndoe",        // Unique username
  email: "john@example.com",  // User's email
  name: "John Doe",           // Display name
  university: "Central State University",
  year: "Senior",
  accountType: "activeMember" | "undergradAlumni",
  bio: "User bio text",
  profileImageName: "profile_image_url",
  friends: ["user_id_1", "user_id_2"],  // Array of friend user IDs
  favoriteEventIds: ["event_id_1"],     // Array of favorited event IDs
  friendFinderDescription: "Looking for...",
  notificationAdvanceMinutes: 30,
  
  // Active Member specific fields
  applicationData: {          // Optional - for Active Members
    fullName: "John Doe",
    classification: "Senior",
    isInvolvedInOrgs: "true"
  },
  isPaymentActive: true,      // Payment status
  subscriptionStatus: "active" | "promo" | "expired",
  subscriptionStartDate: Timestamp
}
```

### Operations:
- **Create**: When user signs up (`signUp` function)
- **Read**: Get user by ID, search users
- **Update**: Update profile, add friends, update payment status
- **Delete**: User account deletion

---

## 2. `events` Collection

Stores event posts created by users.

### Document Structure:
```javascript
{
  id: "event_id",             // Auto-generated document ID
  creatorId: "user_id",       // ID of user who created the event
  title: "Basketball Game",
  description: "Join us for...",
  date: Timestamp,            // Event date/time
  location: "Gymnasium",
  category: "Sports",
  imageName: "event_image_url",
  attending: ["user_id_1", "user_id_2"],  // Array of user IDs attending
  likedBy: ["user_id_3"],                 // Array of user IDs who liked
  maxAttendees: 50,           // Optional max attendees
  university: "Central State University",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

### Operations:
- **Create**: When user creates an event (`createEvent`)
- **Read**: Get all events, get events by creator, observe real-time updates
- **Update**: Update event details, add attendees, toggle likes
- **Delete**: Delete event

### Indexes Required:
- `date` (ascending) - For sorting events by date
- `creatorId` (ascending) - For filtering events by creator

---

## 3. `conversations` Collection

Stores conversation metadata between users.

### Document Structure:
```javascript
{
  id: "conversation_id",      // Auto-generated document ID
  participants: ["user_id_1", "user_id_2"],  // Array of participant user IDs
  lastMessage: "Hey, how are you?",          // Last message text
  lastMessageTimestamp: Timestamp,          // When last message was sent
  lastMessageSenderId: "user_id_1",         // Who sent the last message
  unreadCount: {              // Unread count per user
    "user_id_1": 0,
    "user_id_2": 5
  },
  createdAt: Timestamp
}
```

### Operations:
- **Create**: When users start a new conversation
- **Read**: Get user's conversations, get conversation by ID
- **Update**: Update last message, update unread counts, mark as read
- **Delete**: Delete conversation

### Indexes Required:
- `participants` (array-contains) + `lastMessageTimestamp` (descending) - For user's conversation list

---

## 4. `conversations/{conversationId}/messages` Subcollection

Individual messages within a conversation.

### Document Structure:
```javascript
{
  id: "message_id",           // Auto-generated document ID
  senderId: "user_id_1",      // Who sent the message
  receiverId: "user_id_2",    // Who received the message
  text: "Hello! How are you?",
  timestamp: Timestamp,       // When message was sent
  read: false,                // Whether message has been read
  type: "text"                // Message type (text, image, etc.)
}
```

### Operations:
- **Create**: Send new message (`sendMessage`)
- **Read**: Get messages for conversation, observe real-time updates
- **Update**: Mark message as read
- **Delete**: Delete message (optional)

### Indexes Required:
- `timestamp` (ascending) - For sorting messages chronologically
- `receiverId` + `read` - For unread message queries

---

## Security Rules

### Recommended Firestore Security Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper function to check if user is authenticated
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Helper function to check if user owns the document
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      // Users can read their own profile or any user's profile (for friend search)
      allow read: if isAuthenticated();
      // Users can only write their own profile
      allow write: if isOwner(userId);
    }
    
    // Events collection
    match /events/{eventId} {
      // Authenticated users can read all events
      allow read: if isAuthenticated();
      // Any authenticated user can create events
      allow create: if isAuthenticated() && 
                       request.resource.data.creatorId == request.auth.uid;
      // Only the creator can update or delete their events
      allow update, delete: if isAuthenticated() && 
                              resource.data.creatorId == request.auth.uid;
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      // Users can read conversations they're a participant in
      allow read: if isAuthenticated() && 
                     request.auth.uid in resource.data.participants;
      // Users can create conversations they're a participant in
      allow create: if isAuthenticated() && 
                       request.auth.uid in request.resource.data.participants;
      // Users can update conversations they're a participant in
      allow update: if isAuthenticated() && 
                      request.auth.uid in resource.data.participants;
      // Users can delete conversations they're a participant in
      allow delete: if isAuthenticated() && 
                      request.auth.uid in resource.data.participants;
      
      // Messages subcollection
      match /messages/{messageId} {
        // Users can read messages in conversations they're part of
        allow read: if isAuthenticated() && 
                       request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants;
        // Users can send messages if they're a participant
        allow create: if isAuthenticated() && 
                         (request.resource.data.senderId == request.auth.uid) &&
                         (request.resource.data.receiverId in get(/databases/$(database)/documents/conversations/$(conversationId)).data.participants);
        // Users can update their own messages or mark received messages as read
        allow update: if isAuthenticated() && 
                        ((resource.data.senderId == request.auth.uid) ||
                         (resource.data.receiverId == request.auth.uid && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['read'])));
        // Users can delete their own messages
        allow delete: if isAuthenticated() && 
                        resource.data.senderId == request.auth.uid;
      }
    }
  }
}
```

---

## Setting Up Firestore Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **get-active-99ab7**
3. Go to **Firestore Database** → **Rules** tab
4. Paste the security rules above
5. Click **Publish**

---

## Required Indexes

Firestore will prompt you to create indexes when needed. However, you can create them proactively:

### Indexes to Create:

1. **Conversations Index**:
   - Collection: `conversations`
   - Fields:
     - `participants` (Array-contains)
     - `lastMessageTimestamp` (Descending)
   - Query scope: Collection

2. **Messages Index**:
   - Collection: `conversations/{conversationId}/messages`
   - Fields:
     - `timestamp` (Ascending)
   - Query scope: Collection

3. **Events Index** (if needed):
   - Collection: `events`
   - Fields:
     - `date` (Ascending)
   - Query scope: Collection

To create indexes:
1. Go to Firestore → **Indexes** tab
2. Click **Create Index**
3. Fill in the fields above
4. Click **Create**

---

## Collection Initialization

The app automatically initializes collections on first run by creating placeholder documents. These are safe to delete and will be cleaned up when real data is added.

The `FirestoreSetup` class handles:
- Collection verification
- Structure validation
- Initial marker cleanup

---

## Testing Collections

After setting up, you can verify collections work by:

1. **Sign up** a new user → Creates entry in `users`
2. **Create an event** → Creates entry in `events`
3. **Start a conversation** → Creates entry in `conversations` and `messages` subcollection

All collections are created automatically when data is written, so you don't need to manually create empty collections.

