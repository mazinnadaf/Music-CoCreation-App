import Foundation
import SwiftUI
import Combine

class FriendsManager: ObservableObject {
    @Published var friends: [User] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var searchResults: [User] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let firebaseManager = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        firebaseManager.$friends
            .assign(to: \.friends, on: self)
            .store(in: &cancellables)
        
        firebaseManager.$friendRequests
            .assign(to: \.friendRequests, on: self)
            .store(in: &cancellables)
    }
    
    func initialize(with userId: String) {
        self.currentUserId = userId
        loadFriends()
        loadFriendRequests()
    }
    
    func loadFriends() {
        guard let userId = currentUserId else { return }
        firebaseManager.loadFriends(for: userId)
    }
    
    func loadFriendRequests() {
        guard let userId = currentUserId else { return }
        firebaseManager.loadFriendRequests(for: userId)
    }
    
    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                self.searchResults = []
            }
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            let users = try await firebaseManager.searchUsers(query: query)
            await MainActor.run {
                // Filter out current user and existing friends
                self.searchResults = users.filter { user in
                    user.id != self.currentUserId && 
                    !self.friends.contains { $0.id == user.id }
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to search users: \(error.localizedDescription)"
                self.isLoading = false
                self.searchResults = []
            }
        }
    }
    
    func sendFriendRequest(to user: User) async {
        guard let currentUserId = currentUserId else { 
            print("❌ No current user ID available")
            return 
        }
        
        // Check if friend request already exists
        let targetUserId = user.id
        print("👤 Sending friend request:")
        print("   Current user ID: \(currentUserId)")
        print("   Target user ID: \(targetUserId)")
        print("   Target username: \(user.username)")
        
        let existingRequest = friendRequests.first { request in
            (request.senderId == currentUserId && request.receiverId == targetUserId) ||
            (request.senderId == targetUserId && request.receiverId == currentUserId)
        }
        
        if existingRequest != nil {
            await MainActor.run {
                self.error = "Friend request already exists"
            }
            return
        }
        
        do {
            try await firebaseManager.sendFriendRequest(to: targetUserId, from: currentUserId)
            await MainActor.run {
                self.error = nil
                print("✅ Friend request sent from \(currentUserId) to \(targetUserId)")
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to send friend request: \(error.localizedDescription)"
                print("❌ Error sending friend request: \(error)")
            }
        }
    }
    
    func acceptFriendRequest(_ request: FriendRequest) async {
        do {
            try await firebaseManager.respondToFriendRequest(requestId: request.id, accept: true)
            await MainActor.run {
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to accept friend request: \(error.localizedDescription)"
            }
        }
    }
    
    func declineFriendRequest(_ request: FriendRequest) async {
        do {
            try await firebaseManager.respondToFriendRequest(requestId: request.id, accept: false)
            await MainActor.run {
                self.error = nil
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to decline friend request: \(error.localizedDescription)"
            }
        }
    }
    
    func removeFriend(_ friend: User) async {
        // TODO: Implement remove friend functionality
        // This would involve removing the friend from both users' friend lists
    }
    
    func getFriendRequestSender(_ request: FriendRequest) async -> User? {
        do {
            return try await firebaseManager.getUser(by: request.senderId)
        } catch {
            await MainActor.run {
                self.error = "Failed to get friend request sender: \(error.localizedDescription)"
            }
            return nil
        }
    }
}
