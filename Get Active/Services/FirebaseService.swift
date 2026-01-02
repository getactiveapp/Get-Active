import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Firebase service layer for backend integration
class FirebaseService {
    static let shared = FirebaseService()
    
    private let db: Firestore
    private let storage: Storage
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        self.db = Firestore.firestore()
        self.storage = Storage.storage()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
    }
    
    // MARK: - Authentication
    
    /// Sign up a new user
    func signUp(email: String, password: String, userData: [String: Any], completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user"])))
                return
            }
            
            // Create user document in Firestore
            var userDataWithId = userData
            userDataWithId["id"] = user.uid
            userDataWithId["email"] = email
            userDataWithId["createdAt"] = Timestamp(date: Date())
            userDataWithId["updatedAt"] = Timestamp(date: Date())
            
            self?.db.collection("users").document(user.uid).setData(userDataWithId) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Convert to app User model
                    if let appUser = self?.convertToAppUser(uid: user.uid, data: userDataWithId) {
                        completion(.success(appUser))
                    } else {
                        completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user model"])))
                    }
                }
            }
        }
    }
    
    /// Sign in user
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to sign in"])))
                return
            }
            
            // Fetch user data from Firestore
            self?.db.collection("users").document(user.uid).getDocument { document, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data(),
                      let appUser = self?.convertToAppUser(uid: user.uid, data: data) else {
                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                    return
                }
                
                completion(.success(appUser))
            }
        }
    }
    
    /// Sign out user
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    /// Get current user
    func getCurrentUser(completion: @escaping (Result<User, Error>) -> Void) {
        guard let firebaseUser = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])))
            return
        }
        
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let appUser = self?.convertToAppUser(uid: firebaseUser.uid, data: data) else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                return
            }
            
            completion(.success(appUser))
        }
    }
    
    /// Update user data
    func updateUser(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])))
            return
        }
        
        var userData = convertToFirestoreData(user)
        userData["updatedAt"] = Timestamp()
        
        db.collection("users").document(uid).updateData(userData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Delete user account
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user signed in"])))
            return
        }
        
        // Delete user document
        db.collection("users").document(user.uid).delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Delete auth user
            user.delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    /// Listen to auth state changes
    func observeAuthState(completion: @escaping (User?) -> Void) {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            if let firebaseUser = firebaseUser {
                self?.db.collection("users").document(firebaseUser.uid).getDocument { document, error in
                    if let document = document, document.exists,
                       let data = document.data(),
                       let appUser = self?.convertToAppUser(uid: firebaseUser.uid, data: data) {
                        completion(appUser)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        }
    }
    
    /// Remove auth state listener
    func removeAuthStateListener() {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
            authStateListener = nil
        }
    }
    
    // MARK: - Events
    
    /// Create event
    func createEvent(_ event: Event, completion: @escaping (Result<String, Error>) -> Void) {
        var eventData = convertEventToFirestoreData(event)
        eventData["createdAt"] = Timestamp(date: Date())
        eventData["updatedAt"] = Timestamp(date: Date())
        
        var ref: DocumentReference?
        ref = db.collection("events").addDocument(data: eventData) { error in
            if let error = error {
                completion(.failure(error))
            } else if let eventId = ref?.documentID {
                completion(.success(eventId))
            } else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get event ID"])))
            }
        }
    }
    
    /// Get all events
    func getEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        db.collection("events")
            .order(by: "date", descending: false)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let events = documents.compactMap { doc -> Event? in
                    self?.convertDocumentToEvent(doc)
                }
                
                completion(.success(events))
            }
    }
    
    /// Update event
    func updateEvent(_ event: Event, completion: @escaping (Result<Void, Error>) -> Void) {
        guard !event.id.isEmpty else {
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Event ID is required"])))
            return
        }
        
        var eventData = convertEventToFirestoreData(event)
        eventData["updatedAt"] = Timestamp(date: Date())
        
        db.collection("events").document(event.id).updateData(eventData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Delete event
    func deleteEvent(eventId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("events").document(eventId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    /// Listen to events changes
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
        db.collection("events")
            .order(by: "date", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let events = documents.compactMap { doc -> Event? in
                    self?.convertDocumentToEvent(doc)
                }
                
                completion(.success(events))
            }
    }
    
    // MARK: - Storage (Images)
    
    /// Upload image to Firebase Storage
    func uploadImage(_ imageData: Data, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        let imageRef = storage.reference().child(path)
        
        imageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToAppUser(uid: String, data: [String: Any]) -> User? {
        guard let email = data["email"] as? String,
              let username = data["username"] as? String,
              let name = data["name"] as? String,
              let accountTypeString = data["accountType"] as? String,
              let accountType = AccountType(rawValue: accountTypeString) else {
            return nil
        }
        
        let password = data["password"] as? String ?? "" // Password not stored in Firebase
        let university = data["university"] as? String ?? ""
        let year = data["year"] as? String ?? ""
        let profileImageName = data["profileImageName"] as? String
        let bio = data["bio"] as? String ?? ""
        let friends = data["friends"] as? [String] ?? []
        let favoriteEventIds = data["favoriteEventIds"] as? [String] ?? []
        let friendFinderImageName = data["friendFinderImageName"] as? String
        let friendFinderDescription = data["friendFinderDescription"] as? String ?? ""
        let notificationAdvanceMinutes = data["notificationAdvanceMinutes"] as? Int ?? 30
        
        return User(
            id: uid,
            email: email,
            username: username,
            password: password,
            name: name,
            university: university,
            year: year,
            profileImageName: profileImageName,
            bio: bio,
            accountType: accountType,
            friends: friends,
            favoriteEventIds: favoriteEventIds,
            friendFinderImageName: friendFinderImageName,
            friendFinderDescription: friendFinderDescription,
            notificationAdvanceMinutes: notificationAdvanceMinutes
        )
    }
    
    private func convertToFirestoreData(_ user: User) -> [String: Any] {
        return [
            "email": user.email,
            "username": user.username,
            "name": user.name,
            "university": user.university,
            "year": user.year,
            "profileImageName": user.profileImageName ?? "",
            "bio": user.bio,
            "accountType": user.accountType.rawValue,
            "friends": user.friends,
            "favoriteEventIds": user.favoriteEventIds,
            "friendFinderImageName": user.friendFinderImageName ?? "",
            "friendFinderDescription": user.friendFinderDescription,
            "notificationAdvanceMinutes": user.notificationAdvanceMinutes
        ]
    }
    
    private func convertEventToFirestoreData(_ event: Event) -> [String: Any] {
        return [
            "title": event.title,
            "description": event.description,
            "date": Timestamp(date: event.date),
            "startTime": event.startTime,
            "endTime": event.endTime,
            "location": event.location,
            "category": event.category.rawValue,
            "tags": event.tags,
            "imageName": event.imageName ?? "",
            "backgroundColor": event.backgroundColor,
            "iconName": event.iconName,
            "createdBy": event.createdBy,
            "isFeatured": event.isFeatured,
            "customImages": event.customImages,
            "likedBy": event.likedBy,
            "rsvpBy": event.rsvpBy,
            "attending": event.attending
        ]
    }
    
    private func convertDocumentToEvent(_ document: QueryDocumentSnapshot) -> Event? {
        let data = document.data()
        
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let location = data["location"] as? String,
              let categoryString = data["category"] as? String,
              let category = EventCategory(rawValue: categoryString),
              let createdBy = data["createdBy"] as? String else {
            return nil
        }
        
        let tags = data["tags"] as? [String] ?? []
        let imageName = data["imageName"] as? String
        let backgroundColor = data["backgroundColor"] as? String ?? "blue"
        let iconName = data["iconName"] as? String ?? "calendar"
        let isFeatured = data["isFeatured"] as? Bool ?? false
        let customImages = data["customImages"] as? [String] ?? []
        let likedBy = data["likedBy"] as? [String] ?? []
        let rsvpBy = data["rsvpBy"] as? [String] ?? []
        let attending = data["attending"] as? [String] ?? []
        
        return Event(
            id: document.documentID,
            title: title,
            description: description,
            date: timestamp.dateValue(),
            startTime: startTime,
            endTime: endTime,
            location: location,
            category: category,
            tags: tags,
            imageName: imageName,
            backgroundColor: backgroundColor,
            iconName: iconName,
            createdBy: createdBy,
            likedBy: likedBy,
            rsvpBy: rsvpBy,
            attending: attending,
            isFeatured: isFeatured,
            customImages: customImages
        )
    }
}
