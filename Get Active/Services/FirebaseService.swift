import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
// import FirebaseDatabase // TODO: Add FirebaseDatabase package in Xcode (see REALTIME_DATABASE_SETUP.md)

/// Firebase service layer for backend integration
class FirebaseService {
    static let shared = FirebaseService()
    
    private let db: Firestore
    private let storage: Storage
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            print("🔵 Initializing Firebase in FirebaseService...")
            FirebaseApp.configure()
            print("✅ Firebase initialized successfully")
        } else {
            print("✅ Firebase already initialized, reusing existing instance")
        }
        
        // Verify Firebase is properly configured
        if let app = FirebaseApp.app() {
            print("✅ Firebase app name: \(app.name), options configured: \(app.options.projectID != nil ? "Yes" : "No")")
            if let projectID = app.options.projectID {
                print("✅ Firebase project ID: \(projectID)")
            } else {
                print("⚠️ Warning: Firebase project ID not found - GoogleService-Info.plist may be missing or invalid")
            }
        }
        
        self.db = Firestore.firestore()
        self.storage = Storage.storage()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
        
        // Test Firestore connection and warn if database doesn't exist
        db.document("_test_connection/_exists").getDocument { snapshot, error in
            if let error = error as NSError? {
                if error.domain == "FIRFirestoreErrorDomain" && error.code == 5 {
                    // Error code 5 = NOT_FOUND - Database doesn't exist
                    print("⚠️ ⚠️ ⚠️ FIRESTORE DATABASE NOT FOUND ⚠️ ⚠️ ⚠️")
                    print("⚠️ The Firestore database does not exist for this project.")
                    print("⚠️ To fix this:")
                    print("⚠️ 1. Go to: https://console.cloud.google.com/firestore/databases?project=get-active-99ab7")
                    print("⚠️ 2. Click 'Create Database'")
                    print("⚠️ 3. Choose 'Start in production mode' or 'Start in test mode'")
                    print("⚠️ 4. Select a location for your database")
                    print("⚠️ 5. Click 'Enable'")
                    print("⚠️ After creating the database, restart the app.")
                } else {
                    print("⚠️ Firestore connection test failed: \(error.localizedDescription)")
                }
            } else {
                // Database exists, initialize collections
                print("✅ Firestore database is accessible, initializing collections...")
                FirestoreSetup.shared.initializeCollections { success, error in
                    if success {
                        print("✅ All Firestore collections are ready!")
                        // Verify collections are accessible
                        FirestoreSetup.shared.verifyCollections { allReady in
                            if allReady {
                                print("✅ All collections verified and ready for use")
                            } else {
                                print("⚠️ Some collections may not be accessible")
                            }
                        }
                    } else {
                        print("⚠️ Collection initialization had issues: \(error ?? "unknown error")")
                    }
                }
            }
        }
    }
    
    // MARK: - Authentication
    
    /// Sign up a new user
    func signUp(email: String, password: String, userData: [String: Any], completion: @escaping (Result<User, Error>) -> Void) {
        print("🔵 Starting Firebase sign-up for: \(email)")
        
        // Verify Firebase is configured
        guard FirebaseApp.app() != nil else {
            print("❌ Firebase not initialized")
            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase is not configured. Please check your GoogleService-Info.plist file."])))
            return
        }
        
        print("✅ Firebase is initialized")
        
        // Double-check Firebase Auth is available
        let auth = Auth.auth()
        print("🔵 Auth instance created, current user: \(auth.currentUser?.uid ?? "none")")
        
        auth.createUser(withEmail: email, password: password) { [weak self] authResult, error in
            // Ensure we're on main thread for completion
            DispatchQueue.main.async {
                // Check for error first
                if let error = error {
                    let userFriendlyError = self?.convertFirebaseError(error) ?? error
                    print("❌ Firebase Auth sign-up error: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ Error code: \(nsError.code), domain: \(nsError.domain), userInfo: \(nsError.userInfo)")
                    }
                    completion(.failure(userFriendlyError))
                    return
                }
                
                // Verify result is not nil
                guard let authResult = authResult else {
                    print("❌ Firebase sign-up returned nil result and nil error")
                    print("❌ This usually means Firebase Auth is not properly configured")
                    print("❌ Checking Firebase app state...")
                    if let app = FirebaseApp.app() {
                        print("❌ Firebase app exists but Auth returned nil - check Firebase Console: Authentication must be enabled")
                    } else {
                        print("❌ Firebase app is nil - GoogleService-Info.plist may be missing")
                    }
                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase Authentication is not properly configured. Please ensure:\n1. GoogleService-Info.plist is added to your project\n2. Email/Password authentication is enabled in Firebase Console\n3. Your Firebase project is properly set up"])))
                    return
                }
                
                // Get user from result
                let user = authResult.user
            print("✅ Firebase Auth user created: \(user.uid), email: \(user.email ?? "no email")")
            
            // Create user document in Firestore
            var userDataWithId = userData
            userDataWithId["id"] = user.uid
            userDataWithId["email"] = email
            userDataWithId["createdAt"] = Timestamp(date: Date())
            userDataWithId["updatedAt"] = Timestamp(date: Date())
            
                print("🔵 Saving user data to Firestore...")
                self?.db.collection("users").document(user.uid).setData(userDataWithId) { error in
                    if let error = error {
                        print("❌ Firestore save error: \(error.localizedDescription)")
                        // Try to delete the auth user if Firestore save fails
                        user.delete { _ in }
                        completion(.failure(error))
                    } else {
                        print("✅ Firestore data saved successfully")
                        // Convert to app User model
                        if let appUser = self?.convertToAppUser(uid: user.uid, data: userDataWithId) {
                            print("✅ User model created successfully: \(appUser.username)")
                            completion(.success(appUser))
                        } else {
                            print("❌ Failed to convert to User model. Data keys: \(userDataWithId.keys.joined(separator: ", "))")
                            print("❌ AccountType value: \(userData["accountType"] ?? "nil")")
                            // Try to delete the auth user if conversion fails
                            user.delete { _ in }
                            completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create user profile. Please try again."])))
                        }
                    }
                }
            }
        }
    }
    
    /// Sign in user
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        print("🔵 Starting Firebase sign-in for: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                let userFriendlyError = self?.convertFirebaseError(error) ?? error
                print("❌ Firebase Auth sign-in error: \(error.localizedDescription)")
                if let nsError = error as NSError? {
                    print("❌ Error code: \(nsError.code), domain: \(nsError.domain)")
                }
                completion(.failure(userFriendlyError))
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
    
    /// Get user by ID (for viewing other users' profiles)
    func getUser(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let appUser = self?.convertToAppUser(uid: uid, data: data) else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
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
    @discardableResult
    func observeEvents(completion: @escaping (Result<[Event], Error>) -> Void) -> NSObjectProtocol {
        return db.collection("events")
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
    
    // MARK: - User Search
    
    /// Search for users by username or name
    func searchUsers(query: String, completion: @escaping (Result<[User], Error>) -> Void) {
        guard !query.isEmpty else {
            completion(.success([]))
            return
        }
        
        let lowercaseQuery = query.lowercased()
        let currentUserId = Auth.auth().currentUser?.uid
        
        // Get all users and filter client-side (Firestore doesn't support case-insensitive search directly)
        // For better performance with many users, consider adding lowercase fields to Firestore
        db.collection("users")
            .limit(to: 100) // Limit to reasonable number for client-side filtering
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                // Filter users client-side by username or name (case-insensitive)
                let matchingUsers = documents.compactMap { doc -> User? in
                    let data = doc.data()
                    guard let appUser = self?.convertToAppUser(uid: doc.documentID, data: data),
                          // Exclude current user
                          appUser.id != currentUserId else {
                        return nil
                    }
                    
                    // Check if query matches username or name (case-insensitive)
                    let usernameMatch = appUser.username.lowercased().contains(lowercaseQuery)
                    let nameMatch = appUser.name.lowercased().contains(lowercaseQuery)
                    
                    return (usernameMatch || nameMatch) ? appUser : nil
                }
                
                // Sort: exact username matches first, then name matches, then alphabetical
                let sortedUsers = matchingUsers.sorted { user1, user2 in
                    let user1UsernameExact = user1.username.lowercased() == lowercaseQuery
                    let user2UsernameExact = user2.username.lowercased() == lowercaseQuery
                    
                    if user1UsernameExact != user2UsernameExact {
                        return user1UsernameExact
                    }
                    
                    return user1.username.lowercased() < user2.username.lowercased()
                }
                
                completion(.success(Array(sortedUsers.prefix(20))))
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
    
    // MARK: - Diagnostic Methods
    
    /// Diagnostic function to verify Firebase connection and list all users
    func diagnoseFirebaseConnection(completion: @escaping (String) -> Void) {
        var report = "=== Firebase Diagnostic Report ===\n\n"
        
        // 1. Check Firebase App initialization
        if let app = FirebaseApp.app() {
            report += "✅ Firebase App Initialized\n"
            report += "   - App Name: \(app.name)\n"
            if let projectID = app.options.projectID {
                report += "   - Project ID: \(projectID)\n"
            } else {
                report += "   ❌ Project ID: NOT FOUND\n"
            }
            report += "   - Bundle ID: \(app.options.bundleID ?? "Unknown")\n"
            if let apiKey = app.options.apiKey {
                report += "   - API Key: \(String(apiKey.prefix(20)))...\n"
            }
        } else {
            report += "❌ Firebase App NOT Initialized\n"
        }
        
        // 2. Check Firestore connection
        report += "\n--- Firestore Connection Test ---\n"
        db.collection("users").limit(to: 1).getDocuments { snapshot, error in
            if let error = error {
                report += "❌ Firestore Error: \(error.localizedDescription)\n"
                if let nsError = error as NSError? {
                    report += "   - Domain: \(nsError.domain)\n"
                    report += "   - Code: \(nsError.code)\n"
                    if nsError.code == 5 {
                        report += "   ⚠️ DATABASE NOT FOUND - Create Firestore database\n"
                    } else if nsError.code == 7 {
                        report += "   ⚠️ PERMISSION DENIED - Check security rules\n"
                    }
                }
            } else {
                report += "✅ Firestore Connection: SUCCESS\n"
            }
            
            // 3. Count users
            self.db.collection("users").getDocuments { snapshot, error in
                if let error = error {
                    report += "\n❌ Error counting users: \(error.localizedDescription)\n"
                } else {
                    let count = snapshot?.documents.count ?? 0
                    report += "\n--- Users Collection ---\n"
                    report += "   - Total Users: \(count)\n"
                    
                    if count > 0, let documents = snapshot?.documents {
                        report += "\n   Sample Users (first 5):\n"
                        for (index, doc) in documents.prefix(5).enumerated() {
                            let data = doc.data()
                            let name = data["name"] as? String ?? "Unknown"
                            let username = data["username"] as? String ?? "Unknown"
                            let email = data["email"] as? String ?? "Unknown"
                            report += "   \(index + 1). \(name) (@\(username)) - \(email)\n"
                        }
                    } else {
                        report += "   ⚠️ No users found in database\n"
                    }
                }
                
                // 4. Check current auth user
                report += "\n--- Authentication Status ---\n"
                if let user = Auth.auth().currentUser {
                    report += "✅ User Signed In\n"
                    report += "   - UID: \(user.uid)\n"
                    report += "   - Email: \(user.email ?? "No email")\n"
                    
                    // Try to fetch user document
                    self.db.collection("users").document(user.uid).getDocument { document, error in
                        if let error = error {
                            report += "   ❌ Error fetching user document: \(error.localizedDescription)\n"
                        } else if let document = document, document.exists {
                            let data = document.data() ?? [:]
                            let name = data["name"] as? String ?? "Unknown"
                            let username = data["username"] as? String ?? "Unknown"
                            report += "   ✅ User Document Found\n"
                            report += "   - Name: \(name)\n"
                            report += "   - Username: \(username)\n"
                        } else {
                            report += "   ⚠️ User document does NOT exist in Firestore\n"
                        }
                        
                        report += "\n=== End Report ===\n"
                        completion(report)
                    }
                } else {
                    report += "⚠️ No User Signed In\n"
                    report += "\n=== End Report ===\n"
                    completion(report)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Convert Firebase Auth error to user-friendly message
    private func convertFirebaseError(_ error: Error) -> NSError {
        guard let nsError = error as NSError? else {
            return NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
        }
        
        // Firebase Auth error codes (from FIRAuthErrorCode enum)
        let errorCode = nsError.code
        let message: String
        
        // Check the error code and Firebase Auth error domain
        if nsError.domain == "FIRAuthErrorDomain" {
            switch errorCode {
            case 17007: // FIRAuthErrorCodeEmailAlreadyInUse
                message = "This email is already registered. Please log in instead."
            case 17026: // FIRAuthErrorCodeWeakPassword
                message = "Password is too weak. Please use at least 6 characters."
            case 17008: // FIRAuthErrorCodeInvalidEmail
                message = "Invalid email address. Please check and try again."
            case 17020: // FIRAuthErrorCodeNetworkError
                message = "Network error. Please check your connection and try again."
            case 17006: // FIRAuthErrorCodeOperationNotAllowed
                message = "Email/password accounts are not enabled. Please contact support."
            case 17010: // FIRAuthErrorCodeTooManyRequests
                message = "Too many attempts. Please try again later."
            case 17005: // FIRAuthErrorCodeUserDisabled
                message = "This account has been disabled. Please contact support."
            case 17011: // FIRAuthErrorCodeWrongPassword
                message = "Incorrect password. Please try again."
            case 17025: // FIRAuthErrorCodeUserNotFound
                message = "No account found with this email. Please sign up first."
            default:
                // Use the Firebase error message, or a generic one
                let originalMessage = nsError.localizedDescription
                message = originalMessage.isEmpty ? "An error occurred during sign up. Please try again." : originalMessage
            }
        } else {
            // Not a Firebase Auth error, use original message
            message = nsError.localizedDescription.isEmpty ? "An error occurred. Please try again." : nsError.localizedDescription
        }
        
        return NSError(domain: "FirebaseService", code: nsError.code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    /// Convert Firestore data to User model (public for use in dashboard)
    func convertToAppUser(uid: String, data: [String: Any]) -> User? {
        guard let email = data["email"] as? String else {
            print("❌ Missing email in user data")
            return nil
        }
        guard let username = data["username"] as? String else {
            print("❌ Missing username in user data")
            return nil
        }
        guard let name = data["name"] as? String else {
            print("❌ Missing name in user data")
            return nil
        }
        guard let accountTypeString = data["accountType"] as? String else {
            print("❌ Missing accountType in user data. Available keys: \(data.keys.joined(separator: ", "))")
            return nil
        }
        guard let accountType = AccountType(rawValue: accountTypeString) else {
            print("❌ Invalid accountType value: '\(accountTypeString)'. Valid values: activeMember, undergradAlumni")
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
        
        // Parse application data
        var applicationData: [String: Any]? = nil
        if let appData = data["applicationData"] as? [String: Any] {
            applicationData = appData
        } else if let appDataString = data["applicationData"] as? [String: String] {
            applicationData = appDataString
        }
        
        // Parse payment/subscription info
        let isPaymentActive = data["isPaymentActive"] as? Bool ?? false
        let subscriptionStatus = data["subscriptionStatus"] as? String
        let subscriptionStartDate: Date? = {
            if let timestamp = data["subscriptionStartDate"] as? Timestamp {
                return timestamp.dateValue()
            }
            return nil
        }()
        
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
            notificationAdvanceMinutes: notificationAdvanceMinutes,
            applicationData: applicationData,
            isPaymentActive: isPaymentActive,
            subscriptionStatus: subscriptionStatus,
            subscriptionStartDate: subscriptionStartDate
        )
    }
    
    private func convertToFirestoreData(_ user: User) -> [String: Any] {
        var data: [String: Any] = [
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
            "notificationAdvanceMinutes": user.notificationAdvanceMinutes,
            "isPaymentActive": user.isPaymentActive
        ]
        
        // Add application data if present
        if let appData = user.applicationData {
            // Convert [String: Any] to Firestore-compatible format
            if let stringDict = appData as? [String: String] {
                data["applicationData"] = stringDict
            } else {
                // Convert Any values to strings for Firestore
                var firestoreAppData: [String: String] = [:]
                for (key, value) in appData {
                    firestoreAppData[key] = "\(value)"
                }
                data["applicationData"] = firestoreAppData
            }
        }
        
        // Add subscription info
        if let status = user.subscriptionStatus {
            data["subscriptionStatus"] = status
        }
        if let startDate = user.subscriptionStartDate {
            data["subscriptionStartDate"] = Timestamp(date: startDate)
        }
        
        return data
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
            "iconName": event.iconName ?? "",
            "createdBy": event.createdBy,
            "isFeatured": event.isFeatured,
            "customImages": event.customImages ?? [],
            "likedBy": event.likedBy,
            "rsvpBy": event.rsvpBy,
            "attending": event.attending
        ]
    }
    
    /// Convert Firestore document to Event (public for use in dashboard)
    func convertToEvent(docID: String, data: [String: Any]) -> Event? {
        guard let title = data["title"] as? String,
              let description = data["description"] as? String,
              let timestamp = data["date"] as? Timestamp,
              let startTime = data["startTime"] as? String,
              let endTime = data["endTime"] as? String,
              let location = data["location"] as? String,
              let categoryString = data["category"] as? String,
              let category = EventCategory(rawValue: categoryString) else {
            return nil
        }
        
        let tags = data["tags"] as? [String] ?? []
        let imageName = data["imageName"] as? String
        let backgroundColor = data["backgroundColor"] as? String ?? "blue"
        let iconName = data["iconName"] as? String ?? "calendar"
        let createdBy = data["createdBy"] as? String ?? data["creatorId"] as? String ?? ""
        let isFeatured = data["isFeatured"] as? Bool ?? false
        let customImages = data["customImages"] as? [String] ?? []
        let likedBy = data["likedBy"] as? [String] ?? []
        let rsvpBy = data["rsvpBy"] as? [String] ?? []
        let attending = data["attending"] as? [String] ?? []
        
        return Event(
            id: docID,
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
