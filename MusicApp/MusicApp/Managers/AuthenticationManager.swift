import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    static let userAuthenticated = Notification.Name("userAuthenticated")
}

enum AuthState {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case onboarding
}

class AuthenticationManager: ObservableObject {
    @Published var authState: AuthState = .unauthenticated
    @Published var currentUser: User?
    @Published var hasCompletedOnboarding = false
    
    private var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    init() {
        listenToAuthState()
    }
    
    deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    // MARK: - Firebase Authentication Methods
    func signUp(email: String, password: String, username: String, artistName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        authState = .authenticating
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.authState = .unauthenticated
                    completion(.failure(error))
                }
                return
            }
            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self?.authState = .unauthenticated
                    completion(.failure(NSError(domain: "No user", code: -1)))
                }
                return
            }
            // Create User model and save to Firestore
            let newUser = User(
                id: user.uid, // Use Firebase UID as String
                username: username,
                artistName: artistName,
                bio: "",
                avatar: nil,
                skills: [],
                socialLinks: [],
                stats: UserStats(),
                badges: [],
                joinedDate: Date(),
                isVerified: false,
                friends: [],
                starredTracks: []
            )
            self?.saveUserToFirestore(newUser) { firestoreResult in
                DispatchQueue.main.async {
                    switch firestoreResult {
                    case .success:
                        self?.currentUser = newUser
                        // Since user provided artistName during signup, mark as completed
                        self?.hasCompletedOnboarding = !artistName.isEmpty
                        self?.authState = .authenticated(newUser)
                        print("✅ User signed up successfully, hasCompletedOnboarding: \(self?.hasCompletedOnboarding ?? false)")
                        completion(.success(()))
                    case .failure(let firestoreError):
                        print("❌ Failed to save user to Firestore: \(firestoreError.localizedDescription)")
                        self?.authState = .unauthenticated
                        completion(.failure(firestoreError))
                    }
                }
            }
        }
    }
    
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        authState = .authenticating
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.authState = .unauthenticated
                    completion(.failure(error))
                }
                return
            }
            guard let user = result?.user else {
                DispatchQueue.main.async {
                    self?.authState = .unauthenticated
                    completion(.failure(NSError(domain: "No user", code: -1)))
                }
                return
            }
            // Fetch user profile from Firestore
            self?.fetchUserFromFirestore(uid: user.uid) { fetchResult in
                DispatchQueue.main.async {
                    switch fetchResult {
                    case .success(let userModel):
                        self?.currentUser = userModel
                        // Determine if user has completed onboarding
                        self?.hasCompletedOnboarding = !userModel.artistName.isEmpty
                        self?.authState = .authenticated(userModel)
                        print("✅ User logged in successfully, hasCompletedOnboarding: \(self?.hasCompletedOnboarding ?? false)")
                        completion(.success(()))
                    case .failure(let fetchError):
                        print("❌ Failed to fetch user from Firestore: \(fetchError.localizedDescription)")
                        self?.authState = .unauthenticated
                        completion(.failure(fetchError))
                    }
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            authState = .unauthenticated
            hasCompletedOnboarding = false
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // MARK: - Firestore User Profile
    private func saveUserToFirestore(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        do {
            try db.collection("users").document(user.id).setData(from: user) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    private func fetchUserFromFirestore(uid: String, completion: @escaping (Result<User, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let document = snapshot, document.exists else {
                completion(.failure(NSError(domain: "No user data found", code: -1)))
                return
            }
            
            do {
                let user = try document.data(as: User.self)
                completion(.success(user))
            } catch {
                print("Error decoding user: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Auth State Listener
    private func listenToAuthState() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            if let user = user {
                // Fetch user profile from Firestore
                self.fetchUserFromFirestore(uid: user.uid) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let userModel):
                            self.currentUser = userModel
                            // Check if user has completed basic profile setup
                            self.hasCompletedOnboarding = !userModel.artistName.isEmpty && !userModel.skills.isEmpty
                            self.authState = .authenticated(userModel)
                            // Notify that authentication is complete and user clips should be loaded
                            NotificationCenter.default.post(name: .userAuthenticated, object: nil)
                        case .failure(let error):
                            print("Error fetching user from Firestore: \(error.localizedDescription)")
                            // If user exists in Auth but not in Firestore, sign them out
                            try? Auth.auth().signOut()
                            self.authState = .unauthenticated
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.currentUser = nil
                    self.hasCompletedOnboarding = false
                    self.authState = .unauthenticated
                }
            }
        }
    }
    
    // MARK: - Onboarding/Profile Completion
    func completeProfile(artistName: String, bio: String?, skills: [Skill]) {
        guard var user = currentUser else { return }
        user.artistName = artistName
        user.bio = bio ?? ""
        user.skills = skills
        self.currentUser = user
        self.hasCompletedOnboarding = true
        self.authState = .authenticated(user)
        saveUserToFirestore(user) { _ in }
    }
}

enum SocialProvider: String, CaseIterable {
    case google = "Google"
    case apple = "Apple"
    case tiktok = "TikTok"
    
    var icon: String {
        switch self {
        case .google: return "globe"
        case .apple: return "applelogo"
        case .tiktok: return "music.note"
        }
    }
    
    var color: Color {
        switch self {
        case .google: return .blue
        case .apple: return .black
        case .tiktok: return .pink
        }
    }
}
