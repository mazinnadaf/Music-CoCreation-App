import Foundation
import SwiftUI
import Combine

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
    
    // For demo purposes, we'll store in UserDefaults
    private let userDefaults = UserDefaults.standard
    private let currentUserKey = "currentUser"
    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    
    init() {
        loadStoredUser()
    }
    
    // MARK: - Authentication Methods
    func signInAsGuest() {
        let guestUser = User(username: "guest_\(Int.random(in: 1000...9999))", artistName: "Guest Artist")
        self.currentUser = guestUser
        self.authState = .authenticated(guestUser)
        self.hasCompletedOnboarding = false
    }
    
    func signInWithSocial(provider: SocialProvider) {
        authState = .authenticating
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let username = self.generateUsername(from: provider)
            let user = User(username: username, artistName: username.capitalized)
            self.currentUser = user
            self.authState = .authenticated(user)
            self.saveUser(user)
        }
    }
    
    func completeProfile(artistName: String, bio: String?, skills: [Skill]) {
        guard var user = currentUser else { return }
        
        user.artistName = artistName
        user.bio = bio ?? ""
        user.skills = skills
        
        self.currentUser = user
        self.hasCompletedOnboarding = true
        self.authState = .authenticated(user)
        
        saveUser(user)
        userDefaults.set(true, forKey: hasCompletedOnboardingKey)
    }
    
    func signOut() {
        currentUser = nil
        authState = .unauthenticated
        hasCompletedOnboarding = false
        
        userDefaults.removeObject(forKey: currentUserKey)
        userDefaults.removeObject(forKey: hasCompletedOnboardingKey)
    }
    
    // MARK: - Helper Methods
    private func generateUsername(from provider: SocialProvider) -> String {
        let randomNum = Int.random(in: 100...999)
        switch provider {
        case .google:
            return "artist_g\(randomNum)"
        case .apple:
            return "artist_a\(randomNum)"
        case .tiktok:
            return "artist_t\(randomNum)"
        }
    }
    
    private func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: currentUserKey)
        }
    }
    
    private func loadStoredUser() {
        if let userData = userDefaults.data(forKey: currentUserKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.authState = .authenticated(user)
            self.hasCompletedOnboarding = userDefaults.bool(forKey: hasCompletedOnboardingKey)
        }
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
