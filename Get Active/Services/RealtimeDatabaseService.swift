import Foundation
import FirebaseCore
// NOTE: FirebaseDatabase package must be added in Xcode before this will work
// See REALTIME_DATABASE_SETUP.md for instructions
#if canImport(FirebaseDatabase)
import FirebaseDatabase
#endif

/// Service for managing Realtime Database operations (presence, live updates)
/// NOTE: Requires FirebaseDatabase package to be added in Xcode
/// See REALTIME_DATABASE_SETUP.md for setup instructions
class RealtimeDatabaseService {
    static let shared = RealtimeDatabaseService()
    
    #if canImport(FirebaseDatabase)
    private let database: DatabaseReference
    private var presenceRefs: [String: DatabaseReference] = [:]
    private var onlineStatusListeners: [String: UInt] = [:]
    
    private init() {
        self.database = Database.database().reference()
        print("✅ Realtime Database initialized")
    }
    #else
    private init() {
        print("⚠️ FirebaseDatabase not available. Please add FirebaseDatabase package via Xcode Package Dependencies. See REALTIME_DATABASE_SETUP.md")
    }
    #endif
    
    // MARK: - Presence Tracking
    
    /// Set user as online when app becomes active
    func setUserOnline(userId: String) {
        guard !userId.isEmpty else { return }
        #if canImport(FirebaseDatabase)
        let userStatusRef = database.child("presence").child(userId)
        
        let status: [String: Any] = [
            "status": "online",
            "lastSeen": ServerValue.timestamp(),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        userStatusRef.setValue(status) { error, _ in
            if let error = error {
                print("❌ Error setting user online: \(error.localizedDescription)")
            } else {
                print("✅ User \(userId) set as online")
            }
        }
        
        userStatusRef.onDisconnectSetValue([
            "status": "offline",
            "lastSeen": ServerValue.timestamp(),
            "timestamp": Date().timeIntervalSince1970
        ])
        
        presenceRefs[userId] = userStatusRef
        #else
        print("⚠️ Cannot set user online: FirebaseDatabase not available")
        #endif
    }
    
    /// Set user as offline
    func setUserOffline(userId: String) {
        guard !userId.isEmpty else { return }
        #if canImport(FirebaseDatabase)
        let userStatusRef = database.child("presence").child(userId)
        let status: [String: Any] = [
            "status": "offline",
            "lastSeen": ServerValue.timestamp(),
            "timestamp": Date().timeIntervalSince1970
        ]
        
        userStatusRef.setValue(status) { error, _ in
            if let error = error {
                print("❌ Error setting user offline: \(error.localizedDescription)")
            } else {
                print("✅ User \(userId) set as offline")
            }
        }
        
        // Note: We do   n't explicitly cancel the onDisconnect handler here.
        // When we manually set the value to offline above, it will override
        // any pending onDisconnect operations. The disconnect handler is
        // just a safety net for unexpected disconnects.
        
        // Remove from presence refs tracking
        presenceRefs.removeValue(forKey: userId)
        #else
        print("⚠️ Cannot set user offline: FirebaseDatabase not available")
        #endif
    }
    
    /// Observe online status for a specific user
    func observeUserStatus(userId: String, completion: @escaping (Bool, Date?) -> Void) {
        guard !userId.isEmpty else { return }
        #if canImport(FirebaseDatabase)
        let userStatusRef = database.child("presence").child(userId).child("status")
        
        if let handle = onlineStatusListeners[userId] {
            userStatusRef.removeObserver(withHandle: handle)
        }
        
        let handle = userStatusRef.observe(.value) { snapshot in
            if let status = snapshot.value as? String {
                let isOnline = status == "online"
                let lastSeenRef = self.database.child("presence").child(userId).child("lastSeen")
                lastSeenRef.observeSingleEvent(of: .value) { lastSeenSnapshot in
                    var lastSeen: Date?
                    if let timestamp = lastSeenSnapshot.value as? TimeInterval {
                        lastSeen = Date(timeIntervalSince1970: timestamp / 1000)
                    } else if let timestamp = lastSeenSnapshot.value as? Double {
                        lastSeen = Date(timeIntervalSince1970: timestamp)
                    }
                    completion(isOnline, lastSeen)
                }
            } else {
                completion(false, nil)
            }
        }
        
        onlineStatusListeners[userId] = handle
        #else
        completion(false, nil)
        #endif
    }
    
    /// Observe multiple users' online status
    func observeMultipleUsersStatus(userIds: [String], completion: @escaping ([String: Bool]) -> Void) {
        guard !userIds.isEmpty else {
            completion([:])
            return
        }
        #if canImport(FirebaseDatabase)
        var statuses: [String: Bool] = [:]
        let group = DispatchGroup()
        
        for userId in userIds {
            group.enter()
            let userStatusRef = database.child("presence").child(userId).child("status")
            
            userStatusRef.observeSingleEvent(of: .value) { snapshot in
                if let status = snapshot.value as? String {
                    statuses[userId] = status == "online"
                } else {
                    statuses[userId] = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(statuses)
        }
        #else
        completion([:])
        #endif
    }
    
    /// Remove all listeners for a user
    func removeUserStatusListener(userId: String) {
        #if canImport(FirebaseDatabase)
        guard let handle = onlineStatusListeners[userId] else { return }
        let userStatusRef = database.child("presence").child(userId).child("status")
        userStatusRef.removeObserver(withHandle: handle)
        onlineStatusListeners.removeValue(forKey: userId)
        #endif
    }
    
    /// Clean up all presence listeners
    func cleanup() {
        #if canImport(FirebaseDatabase)
        for (userId, _) in presenceRefs {
            setUserOffline(userId: userId)
        }
        presenceRefs.removeAll()
        
        for (userId, handle) in onlineStatusListeners {
            let userStatusRef = database.child("presence").child(userId).child("status")
            userStatusRef.removeObserver(withHandle: handle)
        }
        onlineStatusListeners.removeAll()
        #endif
    }
    
    // MARK: - Live Event Updates
    
    /// Observe live updates for an event
    func observeEventUpdates(eventId: String, completion: @escaping ([String: Any]) -> Void) {
        #if canImport(FirebaseDatabase)
        let eventRef = database.child("events_live").child(eventId)
        eventRef.observe(.value) { snapshot in
            if let data = snapshot.value as? [String: Any] {
                completion(data)
            }
        }
        #endif
    }
    
    /// Update live event metrics
    func updateEventMetrics(eventId: String, metrics: [String: Any]) {
        #if canImport(FirebaseDatabase)
        let eventRef = database.child("events_live").child(eventId)
        eventRef.updateChildValues(metrics)
        #endif
    }
    
    // MARK: - Typing Indicators
    
    /// Set typing indicator for a conversation
    func setTypingIndicator(conversationId: String, userId: String, isTyping: Bool) {
        #if canImport(FirebaseDatabase)
        let typingRef = database.child("typing").child(conversationId).child(userId)
        typingRef.setValue(isTyping ? true : nil)
        #endif
    }
    
    /// Observe typing indicators
    func observeTypingIndicators(conversationId: String, completion: @escaping ([String: Bool]) -> Void) {
        #if canImport(FirebaseDatabase)
        let typingRef = database.child("typing").child(conversationId)
        typingRef.observe(.value) { snapshot in
            var typingStatuses: [String: Bool] = [:]
            if let data = snapshot.value as? [String: Bool] {
                typingStatuses = data
            }
            completion(typingStatuses)
        }
        #endif
    }
    
    /// Remove typing indicator listener
    func removeTypingIndicatorListener(conversationId: String) {
        #if canImport(FirebaseDatabase)
        let typingRef = database.child("typing").child(conversationId)
        typingRef.removeAllObservers()
        #endif
    }
}
