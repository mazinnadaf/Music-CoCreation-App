import SwiftUI

struct MessagesView: View {
    @StateObject private var messagingManager = MessagingManager()
    @StateObject private var friendsManager = FriendsManager()
    @State private var selectedConversation: Conversation?
    @State private var showNewMessage = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.darkBackground.ignoresSafeArea()
                
                if messagingManager.conversations.isEmpty {
                    EmptyMessagesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(messagingManager.conversations) { conversation in
                                ConversationRow(
                                    conversation: conversation,
                                    currentUserId: authManager.currentUser?.id ?? "",
                                    friendsManager: friendsManager
                                ) {
                                    selectedConversation = conversation
                                }
                                
                                Divider()
                                    .background(Color.borderColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewMessage = true }) {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showNewMessage) {
                NewMessageView(
                    friendsManager: friendsManager,
                    messagingManager: messagingManager
                ) { friend in
                    // Handle friend selection - start conversation
                Task {
                    if let conversationId = await messagingManager.startConversation(with: friend.id) {
                        showNewMessage = false
                        // Find the conversation object from the conversations list
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let conversation = messagingManager.conversations.first(where: { 
                                $0.participants.contains(friend.id) && $0.participants.contains(authManager.currentUser?.id ?? "")
                            }) {
                                selectedConversation = conversation
                            }
                        }
                    }
                }
                }
            }
            .sheet(item: $selectedConversation) { conversation in
                ChatView(conversation: conversation, friendsManager: friendsManager)
                    .environmentObject(authManager)
            }
            .onAppear {
                if let currentUser = authManager.currentUser {
                    messagingManager.initialize(with: currentUser.id)
                    friendsManager.initialize(with: currentUser.id)
                }
            }
        }
    }
}

// MARK: - Empty State
struct EmptyMessagesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text("No messages yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("Start a conversation with other artists")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    let currentUserId: String
    let friendsManager: FriendsManager
    let onTap: () -> Void
    
    @State private var friendInfo: User?
    @State private var isLoadingFriend = true
    
    var friendId: String? {
        conversation.participants.first { $0 != currentUserId }
    }
    
    var friendName: String {
        friendInfo?.artistName ?? friendInfo?.username ?? "Unknown"
    }
    
    var friendInitials: String {
        let name = friendName
        let initials = name.split(separator: " ").compactMap { $0.first }.prefix(2)
        return initials.map(String.init).joined().uppercased()
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(friendInitials.isEmpty ? "?" : friendInitials)
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if isLoadingFriend {
                            Text("Loading...")
                                .font(.headline)
                                .foregroundColor(.secondaryText)
                        } else {
                            Text(friendName)
                                .font(.headline)
                                .foregroundColor(.primaryText)
                        }
                        
                        Spacer()
                        
                        if let lastMessage = conversation.lastMessage {
                            Text(formatTimestamp(lastMessage.timestamp))
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                    }
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.content)
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .lineLimit(1)
                    }
                }
                
                if conversation.unreadCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Text("\(conversation.unreadCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadFriendInfo()
        }
    }
    
    func loadFriendInfo() {
        guard let friendId = friendId else {
            isLoadingFriend = false
            return
        }
        
        // Check if friend is already in the friends list
        if let friend = friendsManager.friends.first(where: { $0.id == friendId }) {
            self.friendInfo = friend
            self.isLoadingFriend = false
        } else {
            // If not in friends list, fetch from Firebase
            Task {
                do {
                    if let user = try await FirebaseManager.shared.getUser(by: friendId) {
                        await MainActor.run {
                            self.friendInfo = user
                            self.isLoadingFriend = false
                        }
                    } else {
                        await MainActor.run {
                            self.isLoadingFriend = false
                        }
                    }
                } catch {
                    await MainActor.run {
                        self.isLoadingFriend = false
                    }
                }
            }
        }
    }
    
    func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Chat View
struct ChatView: View {
    let conversation: Conversation
    let friendsManager: FriendsManager
    @State private var messageText = ""
    @StateObject private var messagingManager = MessagingManager()
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @FocusState private var isMessageFieldFocused: Bool
    @State private var conversationId: String = ""
    @State private var friendInfo: User?
    
    var friendId: String? {
        conversation.participants.first { $0 != authManager.currentUser?.id }
    }
    
    var chatTitle: String {
        friendInfo?.artistName ?? friendInfo?.username ?? "Chat"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                messagesList
                messageInputView
            }
            .navigationTitle(chatTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    chatToolbarButtons
                }
            }
        }
        .onAppear {
            loadMessages()
            loadFriendInfo()
        }
    }
    
    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messagingManager.currentMessages) { message in
                        let isFromCurrentUser = message.senderId == authManager.currentUser?.id
                        MessageBubble(
                            message: message,
                            isFromCurrentUser: isFromCurrentUser
                        )
                        .id(message.id)
                    }
                }
                .padding()
            }
            .background(Color.darkBackground)
            .onChange(of: messagingManager.currentMessages) { messages in
                if let lastMessage = messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onTapGesture {
                isMessageFieldFocused = false
            }
        }
    }
    
    private var messageInputView: some View {
        HStack(spacing: 12) {
            TextField("Type a message...", text: $messageText)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.cardBackground)
                .cornerRadius(20)
                .foregroundColor(.primaryText)
                .focused($isMessageFieldFocused)
            
            Button(action: sendMessage) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Circle())
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(Color.cardBackground)
    }
    
    private var chatToolbarButtons: some View {
        HStack(spacing: 16) {
            Button(action: {}) {
                Image(systemName: "phone")
            }
            Button(action: {}) {
                Image(systemName: "video")
            }
        }
    }
    
    private func sendMessage() {
        guard let currentUserId = authManager.currentUser?.id,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let receiverId = conversation.participants.first(where: { $0 != currentUserId }) else { return }
        
        let messageContent = messageText
        messageText = "" // Clear immediately for better UX
        
        Task {
            await messagingManager.sendMessage(
                content: messageContent,
                to: receiverId,
                in: conversationId
            )
        }
    }
    
    private func loadMessages() {
        if let currentUserId = authManager.currentUser?.id {
            messagingManager.initialize(with: currentUserId)
            
            // Generate conversation ID from participants
            let sortedParticipants = conversation.participants.sorted()
            conversationId = sortedParticipants.joined(separator: "_")
            
            messagingManager.loadMessages(for: conversationId)
        }
    }
    
    private func loadFriendInfo() {
        guard let friendId = friendId else { return }
        
        // Check if friend is already in the friends list
        if let friend = friendsManager.friends.first(where: { $0.id == friendId }) {
            self.friendInfo = friend
        } else {
            // If not in friends list, fetch from Firebase
            Task {
                do {
                    if let user = try await FirebaseManager.shared.getUser(by: friendId) {
                        await MainActor.run {
                            self.friendInfo = user
                        }
                    }
                } catch {
                    print("Error loading friend info: \(error)")
                }
            }
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer() }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Group {
                            if isFromCurrentUser {
                                LinearGradient.primaryGradient
                            } else {
                                Color.cardBackground
                            }
                        }
                    )
                    .foregroundColor(isFromCurrentUser ? .white : .primaryText)
                    .cornerRadius(20)
                
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
            }
            .frame(maxWidth: 280, alignment: isFromCurrentUser ? .trailing : .leading)
            
            if !isFromCurrentUser { Spacer() }
        }
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - New Message View
struct NewMessageView: View {
    @ObservedObject var friendsManager: FriendsManager
    @ObservedObject var messagingManager: MessagingManager
    let onFriendSelected: (User) -> Void
    
    @State private var searchText = ""
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFieldFocused: Bool
    
    var filteredFriends: [User] {
        if searchText.isEmpty {
            return friendsManager.friends
        } else {
            return friendsManager.friends.filter { friend in
                friend.artistName.localizedCaseInsensitiveContains(searchText) ||
                friend.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                searchBar
                friendsList
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                isSearchFieldFocused = false
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryText)
            TextField("Search friends...", text: $searchText)
                .foregroundColor(.primaryText)
                .focused($isSearchFieldFocused)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(8)
        .padding()
    }
    
    private var friendsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if filteredFriends.isEmpty {
                    emptyState
                } else {
                    ForEach(filteredFriends) { friend in
                        FriendRow(
                            name: friend.artistName,
                            subtitle: "@\(friend.username)"
                        ) {
                            onFriendSelected(friend)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondaryText)
            
            Text(searchText.isEmpty ? "No friends yet" : "No friends found")
                .font(.headline)
                .foregroundColor(.secondaryText)
            
            if searchText.isEmpty {
                Text("Add friends to start messaging")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding(.top, 40)
    }
}

struct FriendRow: View {
    let name: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(String(name.prefix(2)).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "message")
                    .foregroundColor(.secondaryText)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    MessagesView()
        .environmentObject(AuthenticationManager())
}
