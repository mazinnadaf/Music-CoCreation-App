import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let auth = Auth.auth()
    
    @Published var friends: [User] = []
    @Published var conversations: [Conversation] = []
    @Published var friendRequests: [FriendRequest] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - User Management
    func saveUser(_ user: User) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "username": user.username.lowercased(), // Store username in lowercase for consistent searching
            "displayUsername": user.username, // Store original username for display
            "artistName": user.artistName,
            "bio": user.bio,
            "avatar": user.avatar ?? "",
            "joinedDate": Timestamp(date: user.joinedDate),
            "isVerified": user.isVerified,
            "friends": user.friends,
            "starredTracks": user.starredTracks
        ]
        
        try await db.collection("users").document(user.id).setData(userData, merge: true)
    }
    
    func getUser(by id: String) async throws -> User? {
        let doc = try await db.collection("users").document(id).getDocument()
        guard doc.exists, let data = doc.data() else { return nil }
        
        return User(
            id: data["id"] as? String ?? id,
            username: data["displayUsername"] as? String ?? data["username"] as? String ?? "", // Use displayUsername if available, fallback to username
            artistName: data["artistName"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            avatar: data["avatar"] as? String,
            skills: [],
            socialLinks: [],
            stats: UserStats(),
            badges: [],
            joinedDate: (data["joinedDate"] as? Timestamp)?.dateValue() ?? Date(),
            isVerified: data["isVerified"] as? Bool ?? false,
            friends: data["friends"] as? [String] ?? [],
            starredTracks: data["starredTracks"] as? [String] ?? []
        )
    }
    
    func searchUsers(query: String) async throws -> [User] {
        // Get all users and filter client-side for more flexible searching
        let snapshot = try await db.collection("users")
            .limit(to: 100) // Get more users for better search results
            .getDocuments()
        
        return try await withThrowingTaskGroup(of: User?.self) { group in
            for doc in snapshot.documents {
                group.addTask {
                    let data = doc.data()
                    let originalUsername = data["username"] as? String ?? ""
                    let displayUsername = data["displayUsername"] as? String ?? originalUsername
                    let artistName = data["artistName"] as? String ?? ""
                    
                    // Check if the query matches username (with @) or artistName (case-insensitive)
                    let queryWithoutAt = query.hasPrefix("@") ? String(query.dropFirst()) : query
                    let usernameMatches = originalUsername.lowercased().contains(queryWithoutAt.lowercased()) ||
                                        displayUsername.lowercased().contains(queryWithoutAt.lowercased())
                    let artistNameMatches = artistName.lowercased().contains(queryWithoutAt.lowercased())
                    
                    if usernameMatches || artistNameMatches {
                        return User(
                            id: data["id"] as? String ?? doc.documentID,
                            username: displayUsername,
                            artistName: artistName,
                            bio: data["bio"] as? String ?? "",
                            avatar: data["avatar"] as? String,
                            skills: [],
                            socialLinks: [],
                            stats: UserStats(),
                            badges: [],
                            joinedDate: (data["joinedDate"] as? Timestamp)?.dateValue() ?? Date(),
                            isVerified: data["isVerified"] as? Bool ?? false,
                            friends: data["friends"] as? [String] ?? [],
                            starredTracks: data["starredTracks"] as? [String] ?? []
                        )
                    }
                    return nil
                }
            }
            
            var results: [User] = []
            for try await user in group {
                if let user = user {
                    results.append(user)
                }
            }
            return results
        }
    }
    
    // MARK: - Friends Management
    func sendFriendRequest(to userId: UUID, from currentUserId: UUID) async throws {
        let friendRequest = FriendRequest(
            senderId: currentUserId,
            receiverId: userId,
            status: .pending
        )
        
        let requestData: [String: Any] = [
            "id": friendRequest.id.uuidString,
            "senderId": friendRequest.senderId.uuidString,
            "receiverId": friendRequest.receiverId.uuidString,
            "status": friendRequest.status.rawValue,
            "sentAt": Timestamp(date: friendRequest.sentAt)
        ]
        
        try await db.collection("friendRequests").document(friendRequest.id.uuidString).setData(requestData)
    }
    
    func respondToFriendRequest(requestId: UUID, accept: Bool) async throws {
        let requestRef = db.collection("friendRequests").document(requestId.uuidString)
        let requestDoc = try await requestRef.getDocument()
        
        guard let requestData = requestDoc.data(),
              let senderIdString = requestData["senderId"] as? String,
              let receiverIdString = requestData["receiverId"] as? String,
              let senderId = UUID(uuidString: senderIdString),
              let receiverId = UUID(uuidString: receiverIdString) else {
            throw NSError(domain: "FirebaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid friend request data"])
        }
        
        if accept {
            // Add each other as friends
            try await addFriend(userId: senderId, friendId: receiverId)
            try await addFriend(userId: receiverId, friendId: senderId)
            
            // Update request status
            try await requestRef.updateData(["status": FriendRequestStatus.accepted.rawValue])
        } else {
            // Update request status
            try await requestRef.updateData(["status": FriendRequestStatus.declined.rawValue])
        }
    }
    
    private func addFriend(userId: UUID, friendId: UUID) async throws {
        try await db.collection("users").document(userId.uuidString).updateData([
            "friends": FieldValue.arrayUnion([friendId.uuidString])
        ])
    }
    
    func loadFriends(for userId: UUID) {
        db.collection("users").document(userId.uuidString)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let data = snapshot?.data(),
                      let friendIds = data["friends"] as? [String] else { return }
                
                Task {
                    do {
                        let friends = try await withThrowingTaskGroup(of: User?.self) { group in
                            for friendId in friendIds {
                                group.addTask {
                                    try await self?.getUser(by: friendId)
                                }
                            }
                            
                            var results: [User] = []
                            for try await friend in group {
                                if let friend = friend {
                                    results.append(friend)
                                }
                            }
                            return results
                        }
                        
                        await MainActor.run {
                            self?.friends = friends
                        }
                    } catch {
                        print("Error loading friends: \(error)")
                    }
                }
            }
    }
    
    func loadFriendRequests(for userId: UUID) {
        db.collection("friendRequests")
            .whereField("receiverId", isEqualTo: userId.uuidString)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                Task {
                    do {
                        let requests = try await withThrowingTaskGroup(of: FriendRequest?.self) { group in
                            for doc in documents {
                                group.addTask {
                                    let data = doc.data()
                                    guard let senderIdString = data["senderId"] as? String,
                                          let receiverIdString = data["receiverId"] as? String,
                                          let senderId = UUID(uuidString: senderIdString),
                                          let receiverId = UUID(uuidString: receiverIdString),
                                          let statusString = data["status"] as? String,
                                          let status = FriendRequestStatus(rawValue: statusString) else {
                                        return nil
                                    }
                                    
                                    return FriendRequest(
                                        id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                                        senderId: senderId,
                                        receiverId: receiverId,
                                        status: status,
                                        sentAt: (data["sentAt"] as? Timestamp)?.dateValue() ?? Date()
                                    )
                                }
                            }
                            
                            var results: [FriendRequest] = []
                            for try await request in group {
                                if let request = request {
                                    results.append(request)
                                }
                            }
                            return results
                        }
                        
                        await MainActor.run {
                            self?.friendRequests = requests
                        }
                    } catch {
                        print("Error loading friend requests: \(error)")
                    }
                }
            }
    }
    
    // MARK: - Messaging
    func createOrGetConversation(between user1: UUID, and user2: UUID) async throws -> String {
        let conversationId = [user1.uuidString, user2.uuidString].sorted().joined(separator: "_")
        let conversationRef = db.collection("conversations").document(conversationId)
        
        let doc = try await conversationRef.getDocument()
        
        if !doc.exists {
            let conversationData: [String: Any] = [
                "id": conversationId,
                "participants": [user1.uuidString, user2.uuidString],
                "createdAt": Timestamp(date: Date()),
                "lastMessage": NSNull(),
                "unreadCounts": [
                    user1.uuidString: 0,
                    user2.uuidString: 0
                ]
            ]
            
            try await conversationRef.setData(conversationData)
        }
        
        return conversationId
    }
    
    func sendMessage(_ message: Message, to conversationId: String) async throws {
        let messageData: [String: Any] = [
            "id": message.id.uuidString,
            "senderId": message.senderId,
            "receiverId": message.receiverId,
            "content": message.content,
            "timestamp": Timestamp(date: message.timestamp),
            "isRead": message.isRead,
            "messageType": message.messageType.rawValue
        ]
        
        let conversationRef = db.collection("conversations").document(conversationId)
        
        // Add message to subcollection
        try await conversationRef.collection("messages").document(message.id.uuidString).setData(messageData)
        
        // Update conversation's last message and unread count
        try await conversationRef.updateData([
            "lastMessage": messageData,
            "unreadCounts.\(message.receiverId)": FieldValue.increment(Int64(1))
        ])
    }
    
    func loadMessages(for conversationId: String) -> AnyPublisher<[Message], Never> {
        let subject = PassthroughSubject<[Message], Never>()
        
        db.collection("conversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    subject.send([])
                    return
                }
                
                let messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    guard let senderId = data["senderId"] as? String,
                          let receiverId = data["receiverId"] as? String,
                          let content = data["content"] as? String,
                          let timestamp = (data["timestamp"] as? Timestamp)?.dateValue(),
                          let messageTypeString = data["messageType"] as? String,
                          let messageType = Message.MessageType(rawValue: messageTypeString) else {
                        return nil
                    }
                    
                    return Message(
                        id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                        senderId: senderId,
                        receiverId: receiverId,
                        content: content,
                        timestamp: timestamp,
                        isRead: data["isRead"] as? Bool ?? false,
                        messageType: messageType
                    )
                }
                
                subject.send(messages)
            }
        
        return subject.eraseToAnyPublisher()
    }
    
    func loadConversations(for userId: UUID) {
        db.collection("conversations")
            .whereField("participants", arrayContains: userId.uuidString)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                Task {
                    let conversations = try await withThrowingTaskGroup(of: Conversation.self) { group in
                        for doc in documents {
                            let data = doc.data()
                            
                            // Validate data before adding task
                            guard let participants = data["participants"] as? [String],
                                  !participants.isEmpty else {
                                continue
                            }
                            
                            group.addTask {
                                var conversation = Conversation(participants: participants)
                                
                                if let lastMessageData = data["lastMessage"] as? [String: Any],
                                   let senderId = lastMessageData["senderId"] as? String,
                                   let receiverId = lastMessageData["receiverId"] as? String,
                                   let content = lastMessageData["content"] as? String,
                                   let timestamp = (lastMessageData["timestamp"] as? Timestamp)?.dateValue(),
                                   let messageTypeString = lastMessageData["messageType"] as? String,
                                   let messageType = Message.MessageType(rawValue: messageTypeString) {
                                    
                                    conversation.lastMessage = Message(
                                        id: UUID(uuidString: lastMessageData["id"] as? String ?? "") ?? UUID(),
                                        senderId: senderId,
                                        receiverId: receiverId,
                                        content: content,
                                        timestamp: timestamp,
                                        isRead: lastMessageData["isRead"] as? Bool ?? false,
                                        messageType: messageType
                                    )
                                }
                                
                                if let unreadCounts = data["unreadCounts"] as? [String: Int] {
                                    conversation.unreadCount = unreadCounts[userId.uuidString] ?? 0
                                }
                                
                                return conversation
                            }
                        }
                        
                        var results: [Conversation] = []
                        for try await conversation in group {
                            results.append(conversation)
                        }
                        return results.sorted { ($0.lastMessage?.timestamp ?? Date.distantPast) > ($1.lastMessage?.timestamp ?? Date.distantPast) }
                    }
                    
                    await MainActor.run {
                        self?.conversations = conversations
                    }
                }
            }
    }
    
    func markMessagesAsRead(in conversationId: String, for userId: UUID) async throws {
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCounts.\(userId.uuidString)": 0
        ])
    }
}

// MARK: - Helper Extensions
extension User {
    init(id: String, username: String, artistName: String, bio: String, avatar: String?, joinedDate: Date, isVerified: Bool, friends: [String], starredTracks: [String]) {
        self.id = id
        self.username = username
        self.artistName = artistName
        self.bio = bio
        self.avatar = avatar
        self.skills = []
        self.socialLinks = []
        self.stats = UserStats()
        self.badges = []
        self.joinedDate = joinedDate
        self.isVerified = isVerified
        self.friends = friends
        self.starredTracks = starredTracks
    }
}
