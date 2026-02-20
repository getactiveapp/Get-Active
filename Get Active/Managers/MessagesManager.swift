import Foundation
import SwiftUI
import FirebaseCore
import FirebaseFirestore

class MessagesManager: ObservableObject {
    static let shared = MessagesManager()
    
    @Published var conversations: [ChatConversation] = []
    @Published var messages: [String: [ChatMessage]] = [:] // Key: conversationId, Value: messages
    
    private let db = Firestore.firestore()
    private var conversationListener: ListenerRemovable?
    private var messageListeners: [String: ListenerRemovable] = [:]
    
    private init() {}
    
    // MARK: - Conversations
    
    /// Load conversations for current user
    func loadConversations(userId: String) {
        // Remove existing listener
        conversationListener?.remove()
        
        // Listen to conversations where user is a participant
        let listener = db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading conversations: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.conversations = []
                    return
                }
                
                self.conversations = documents.compactMap { doc -> ChatConversation? in
                    self.convertDocumentToConversation(doc, currentUserId: userId)
                }
            }
        // Wrap the listener to conform to our protocol
        conversationListener = FirestoreListenerWrapper(listener: listener as AnyObject)
    }
    
    // Wrapper to make Firebase listener conform to our protocol
    private class FirestoreListenerWrapper: ListenerRemovable {
        private let listener: AnyObject
        
        init(listener: AnyObject) {
            self.listener = listener
        }
        
        func remove() {
            // Use performSelector to call remove() if it exists
            if listener.responds(to: Selector(("remove"))) {
                _ = listener.perform(Selector(("remove")))
            }
        }
    }
    
    /// Create or get conversation between two users
    func getOrCreateConversation(userId1: String, userId2: String, completion: @escaping (String?) -> Void) {
        // Check if conversation already exists
        db.collection("conversations")
            .whereField("participants", arrayContains: userId1)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(nil)
                    return
                }
                
                if let error = error {
                    print("Error checking conversations: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                // Find conversation with both users
                if let existingDoc = snapshot?.documents.first(where: { doc in
                    let data = doc.data()
                    let participants = data["participants"] as? [String] ?? []
                    return participants.contains(userId1) && participants.contains(userId2)
                }) {
                    completion(existingDoc.documentID)
                    return
                }
                
                // Fetch user names for the conversation
                self.fetchUserNames(userId1: userId1, userId2: userId2) { name1, name2 in
                    // Create new conversation
                    let conversationData: [String: Any] = [
                        "participants": [userId1, userId2],
                        "participantNames": [
                            userId1: name1,
                            userId2: name2
                        ],
                        "createdAt": Timestamp(date: Date()),
                        "lastMessage": "",
                        "lastMessageTimestamp": Timestamp(date: Date()),
                        "unreadCounts": [
                            userId1: 0,
                            userId2: 0
                        ]
                    ]
                    
                    var ref: DocumentReference?
                    ref = self.db.collection("conversations").addDocument(data: conversationData) { error in
                        if let error = error {
                            print("Error creating conversation: \(error.localizedDescription)")
                            completion(nil)
                        } else {
                            completion(ref?.documentID)
                        }
                    }
                }
            }
    }
    
    /// Fetch user names from Firestore
    private func fetchUserNames(userId1: String, userId2: String, completion: @escaping (String, String) -> Void) {
        let group = DispatchGroup()
        var name1 = userId1
        var name2 = userId2
        
        // Fetch user 1 name
        group.enter()
        db.collection("users").document(userId1).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let name = data["name"] as? String {
                name1 = name
            }
            group.leave()
        }
        
        // Fetch user 2 name
        group.enter()
        db.collection("users").document(userId2).getDocument { snapshot, _ in
            if let data = snapshot?.data(), let name = data["name"] as? String {
                name2 = name
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(name1, name2)
        }
    }
    
    // MARK: - Messages
    
    /// Load messages for a conversation
    func loadMessages(conversationId: String) {
        // Remove existing listener
        if let listener = messageListeners[conversationId] {
            listener.remove()
        }
        
        // Listen to messages in real-time
        let messageListener = db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading messages: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.messages[conversationId] = []
                    return
                }
                
                self.messages[conversationId] = documents.compactMap { doc -> ChatMessage? in
                    self.convertDocumentToMessage(doc)
                }
            }
        
        messageListeners[conversationId] = FirestoreListenerWrapper(listener: messageListener as AnyObject)
    }
    
    /// Send a message
    func sendMessage(conversationId: String, senderId: String, receiverId: String, text: String, completion: @escaping (Bool) -> Void) {
        let messageData: [String: Any] = [
            "senderId": senderId,
            "receiverId": receiverId,
            "text": text,
            "timestamp": Timestamp(date: Date()),
            "read": false
        ]
        
        // Add message to conversation's messages subcollection
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .addDocument(data: messageData) { [weak self] error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                // Update conversation's last message
                self?.db.collection("conversations")
                    .document(conversationId)
                    .updateData([
                        "lastMessage": text,
                        "lastMessageTimestamp": Timestamp(date: Date()),
                        "unreadCounts.\(receiverId)": FieldValue.increment(Int64(1))
                    ]) { error in
                        if let error = error {
                            print("Error updating conversation: \(error.localizedDescription)")
                        }
                        completion(true)
                    }
            }
    }
    
    /// Mark messages as read
    func markAsRead(conversationId: String, userId: String) {
        // Update unread count to 0
        db.collection("conversations")
            .document(conversationId)
            .updateData([
                "unreadCounts.\(userId)": 0
            ]) { error in
                if let error = error {
                    print("Error marking as read: \(error.localizedDescription)")
                }
            }
        
        // Mark all messages as read
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("read", isEqualTo: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error marking messages as read: \(error.localizedDescription)")
                    return
                }
                
                let batch = self.db.batch()
                snapshot?.documents.forEach { doc in
                    batch.updateData(["read": true], forDocument: doc.reference)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error committing batch: \(error.localizedDescription)")
                    }
                }
            }
    }
    
    // MARK: - Cleanup
    
    func removeListeners() {
        conversationListener?.remove()
        messageListeners.values.forEach { $0.remove() }
        conversationListener = nil
        messageListeners.removeAll()
    }
    
    // MARK: - Helper Methods
    
    private func convertDocumentToConversation(_ document: QueryDocumentSnapshot, currentUserId: String) -> ChatConversation? {
        let data = document.data()
        
        guard let participants = data["participants"] as? [String],
              participants.count == 2 else {
            return nil
        }
        
        // Get the other user's ID
        let otherUserId = participants.first { $0 != currentUserId } ?? ""
        
        let lastMessage = data["lastMessage"] as? String ?? ""
        let timestamp = (data["lastMessageTimestamp"] as? Timestamp)?.dateValue() ?? Date()
        let unreadCounts = data["unreadCounts"] as? [String: Int] ?? [:]
        let unreadCount = unreadCounts[currentUserId] ?? 0
        
        // Get friend name from participantNames, or use ID as fallback
        let participantNames = data["participantNames"] as? [String: String] ?? [:]
        let friendName = participantNames[otherUserId] ?? otherUserId
        
        return ChatConversation(
            id: document.documentID,
            friendId: otherUserId,
            friendName: friendName,
            lastMessage: lastMessage,
            timestamp: timestamp,
            unreadCount: unreadCount
        )
    }
    
    private func convertDocumentToMessage(_ document: QueryDocumentSnapshot) -> ChatMessage? {
        let data = document.data()
        
        guard let senderId = data["senderId"] as? String,
              let receiverId = data["receiverId"] as? String,
              let text = data["text"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else {
            return nil
        }
        
        return ChatMessage(
            id: document.documentID,
            senderId: senderId,
            receiverId: receiverId,
            text: text,
            timestamp: timestamp.dateValue()
        )
    }
}


