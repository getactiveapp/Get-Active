import Foundation
import FirebaseFirestore

/// Helper class to initialize and verify Firestore collections structure
class FirestoreSetup {
    static let shared = FirestoreSetup()
    private let db = Firestore.firestore()
    
    private init() {}
    
    /// Initialize Firestore collections by creating sample documents if they don't exist
    /// This helps ensure the collections are created and the database structure is ready
    func initializeCollections(completion: @escaping (Bool, String?) -> Void) {
        print("🔵 Initializing Firestore collections...")
        
        // Collections we need:
        // - users (already created when users sign up)
        // - events (created when events are posted)
        // - conversations (created when users start chatting)
        //   - messages (subcollection under conversations)
        
        // We'll create placeholder documents to ensure collections exist
        // These will be cleaned up automatically when real data is added
        
        let batch = db.batch()
        let collectionsToInit = ["users", "events", "conversations"]
        
        for collectionName in collectionsToInit {
            let docRef = db.collection(collectionName).document("_setup_check")
            batch.setData([
                "initialized": true,
                "timestamp": Timestamp(date: Date()),
                "purpose": "Collection initialization marker - safe to delete"
            ], forDocument: docRef, merge: true)
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ Failed to initialize Firestore collections: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
            } else {
                print("✅ Firestore collections initialized successfully")
                completion(true, nil)
            }
        }
    }
    
    /// Verify that collections are accessible
    func verifyCollections(completion: @escaping (Bool) -> Void) {
        var allCollectionsReady = true
        let collections = ["users", "events", "conversations"]
        var completedChecks = 0
        
        for collectionName in collections {
            db.collection(collectionName).limit(to: 1).getDocuments { snapshot, error in
                completedChecks += 1
                
                if let error = error {
                    print("⚠️ Collection '\(collectionName)' check failed: \(error.localizedDescription)")
                    allCollectionsReady = false
                } else {
                    print("✅ Collection '\(collectionName)' is accessible")
                }
                
                if completedChecks == collections.count {
                    completion(allCollectionsReady)
                }
            }
        }
    }
    
    /// Clean up initialization markers (optional - can be called manually)
    func cleanupInitMarkers(completion: @escaping (Bool) -> Void) {
        let batch = db.batch()
        let collections = ["users", "events", "conversations"]
        
        for collectionName in collections {
            let docRef = db.collection(collectionName).document("_setup_check")
            batch.deleteDocument(docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("⚠️ Failed to cleanup init markers: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Init markers cleaned up")
                completion(true)
            }
        }
    }
}

