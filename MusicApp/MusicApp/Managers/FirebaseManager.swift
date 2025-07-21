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
        // Encode skills
        let skillsData = user.skills.map { skill in
            return [
                "id": skill.id,
                "name": skill.name,
                "icon": skill.icon,
                "level": skill.level.rawValue
            ]
        }
        
        // Encode social links
        let socialLinksData = user.socialLinks.map { link in
            return [
                "id": link.id,
                "platform": link.platform.rawValue,
                "url": link.url
            ]
        }
        
        // Encode stats
        let statsData: [String: Any] = [
            "totalTracks": user.stats.totalTracks,
            "totalCollaborations": user.stats.totalCollaborations,
            "totalPlays": user.stats.totalPlays,
            "totalLikes": user.stats.totalLikes,
            "producerCredits": user.stats.producerCredits,
            "weeklyActive": user.stats.weeklyActive,
            "streak": user.stats.streak
        ]
        
        // Encode badges
        let badgesData = user.badges.map { badge in
            return [
                "id": badge.id,
                "name": badge.name,
                "description": badge.description,
                "icon": badge.icon,
                "earnedDate": Timestamp(date: badge.earnedDate),
                "rarity": badge.rarity.rawValue
            ]
        }
        
        let userData: [String: Any] = [
            "id": user.id,
            "username": user.username.lowercased(), // Store username in lowercase for consistent searching
            "displayUsername": user.username, // Store original username for display
            "artistName": user.artistName,
            "bio": user.bio,
            "avatar": user.avatar ?? "",
            "skills": skillsData,
            "socialLinks": socialLinksData,
            "stats": statsData,
            "badges": badgesData,
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
        
        // Decode skills
        var skills: [Skill] = []
        if let skillsData = data["skills"] as? [[String: Any]] {
            skills = skillsData.compactMap { skillDict in
                guard let name = skillDict["name"] as? String,
                      let icon = skillDict["icon"] as? String,
                      let levelString = skillDict["level"] as? String,
                      let level = Skill.SkillLevel(rawValue: levelString) else { return nil }
                return Skill(name: name, icon: icon, level: level)
            }
        }
        
        // Decode social links
        var socialLinks: [SocialLink] = []
        if let socialLinksData = data["socialLinks"] as? [[String: Any]] {
            socialLinks = socialLinksData.compactMap { linkDict in
                guard let platformString = linkDict["platform"] as? String,
                      let platform = SocialLink.SocialPlatform(rawValue: platformString),
                      let url = linkDict["url"] as? String else { return nil }
                return SocialLink(platform: platform, url: url)
            }
        }
        
        // Decode stats
        var stats = UserStats()
        if let statsData = data["stats"] as? [String: Any] {
            stats.totalTracks = statsData["totalTracks"] as? Int ?? 0
            stats.totalCollaborations = statsData["totalCollaborations"] as? Int ?? 0
            stats.totalPlays = statsData["totalPlays"] as? Int ?? 0
            stats.totalLikes = statsData["totalLikes"] as? Int ?? 0
            stats.producerCredits = statsData["producerCredits"] as? Int ?? 0
            stats.weeklyActive = statsData["weeklyActive"] as? Bool ?? false
            stats.streak = statsData["streak"] as? Int ?? 0
        }
        
        // Decode badges
        var badges: [Badge] = []
        if let badgesData = data["badges"] as? [[String: Any]] {
            badges = badgesData.compactMap { badgeDict in
                guard let name = badgeDict["name"] as? String,
                      let description = badgeDict["description"] as? String,
                      let icon = badgeDict["icon"] as? String,
                      let earnedDate = (badgeDict["earnedDate"] as? Timestamp)?.dateValue(),
                      let rarityString = badgeDict["rarity"] as? String,
                      let rarity = Badge.BadgeRarity(rawValue: rarityString) else { return nil }
                return Badge(name: name, description: description, icon: icon, earnedDate: earnedDate, rarity: rarity)
            }
        }
        
        return User(
            id: data["id"] as? String ?? id,
            username: data["displayUsername"] as? String ?? data["username"] as? String ?? "", // Use displayUsername if available, fallback to username
            artistName: data["artistName"] as? String ?? "",
            bio: data["bio"] as? String ?? "",
            avatar: data["avatar"] as? String,
            skills: skills,
            socialLinks: socialLinks,
            stats: stats,
            badges: badges,
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
    func sendFriendRequest(to userId: String, from currentUserId: String) async throws {
        let friendRequest = FriendRequest(
            senderId: currentUserId,
            receiverId: userId,
            status: .pending
        )
        
        let requestData: [String: Any] = [
            "id": friendRequest.id.uuidString,
            "senderId": friendRequest.senderId,
            "receiverId": friendRequest.receiverId,
            "status": friendRequest.status.rawValue,
            "sentAt": Timestamp(date: friendRequest.sentAt)
        ]
        
        print("🔥 Sending friend request:")
        print("   From: \(currentUserId)")
        print("   To: \(userId)")
        print("   Request ID: \(friendRequest.id.uuidString)")
        
        try await db.collection("friendRequests").document(friendRequest.id.uuidString).setData(requestData)
        print("✅ Friend request saved to Firestore")
    }
    
    func respondToFriendRequest(requestId: UUID, accept: Bool) async throws {
        let requestRef = db.collection("friendRequests").document(requestId.uuidString)
        let requestDoc = try await requestRef.getDocument()
        
        guard let requestData = requestDoc.data(),
              let senderId = requestData["senderId"] as? String,
              let receiverId = requestData["receiverId"] as? String else {
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
    
    private func addFriend(userId: String, friendId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ])
    }
    
    func loadFriends(for userId: String) {
        db.collection("users").document(userId)
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
    
    func loadFriendRequests(for userId: String) {
        print("🔍 Loading friend requests for user: \(userId)")
        
        db.collection("friendRequests")
            .whereField("receiverId", isEqualTo: userId)
            .whereField("status", isEqualTo: FriendRequestStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error loading friend requests: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { 
                    print("⚠️ No documents found in friend requests snapshot")
                    return 
                }
                
                print("📄 Found \(documents.count) friend request documents")
                
                Task {
                    do {
                        let requests = try await withThrowingTaskGroup(of: FriendRequest?.self) { group in
                            for doc in documents {
                                group.addTask {
                                    let data = doc.data()
                                    print("📋 Processing friend request document: \(doc.documentID)")
                                    print("   Data: \(data)")
                                    
                                    guard let senderId = data["senderId"] as? String,
                                          let receiverId = data["receiverId"] as? String,
                                          let statusString = data["status"] as? String,
                                          let status = FriendRequestStatus(rawValue: statusString) else {
                                        print("❌ Invalid friend request data in document: \(doc.documentID)")
                                        return nil
                                    }
                                    
                                    let request = FriendRequest(
                                        id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                                        senderId: senderId,
                                        receiverId: receiverId,
                                        status: status,
                                        sentAt: (data["sentAt"] as? Timestamp)?.dateValue() ?? Date()
                                    )
                                    
                                    print("✅ Successfully parsed friend request: \(request.id)")
                                    return request
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
                        
                        print("📥 Final friend requests count: \(requests.count)")
                        
                        await MainActor.run {
                            self?.friendRequests = requests
                        }
                    } catch {
                        print("❌ Error loading friend requests: \(error)")
                    }
                }
            }
    }
    
    // MARK: - Messaging
    func createOrGetConversation(between user1: String, and user2: String) async throws -> String {
        let conversationId = [user1, user2].sorted().joined(separator: "_")
        let conversationRef = db.collection("conversations").document(conversationId)
        
        let doc = try await conversationRef.getDocument()
        
        if !doc.exists {
            let conversationData: [String: Any] = [
                "id": conversationId,
                "participants": [user1, user2],
                "createdAt": Timestamp(date: Date()),
                "lastMessage": NSNull(),
                "unreadCounts": [
                    user1: 0,
                    user2: 0
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
    
    func loadConversations(for userId: String) {
        db.collection("conversations")
            .whereField("participants", arrayContains: userId)
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
                                    conversation.unreadCount = unreadCounts[userId] ?? 0
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
    
    func markMessagesAsRead(in conversationId: String, for userId: String) async throws {
        try await db.collection("conversations").document(conversationId).updateData([
            "unreadCounts.\(userId)": 0
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
