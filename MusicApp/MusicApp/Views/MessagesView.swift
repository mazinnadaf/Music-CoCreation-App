import SwiftUI

struct MessagesView: View {
    @StateObject private var messagingManager = MessagingManager()
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
                                    currentUserId: authManager.currentUser?.id ?? ""
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
                NewMessageView()
            }
            .sheet(item: $selectedConversation) { conversation in
                ChatView(conversation: conversation)
                    .environmentObject(authManager)
            }
            .onAppear {
                if let currentUser = authManager.currentUser {
                    messagingManager.initialize(with: currentUser.id)
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text("JD") // Placeholder initials
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("John Doe") // Placeholder name
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
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
    @State private var messageText = ""
    @StateObject private var messagingManager = MessagingManager()
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @FocusState private var isMessageFieldFocused: Bool
    @State private var conversationId: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                messagesList
                messageInputView
            }
            .navigationTitle("Chat")
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
        
        let newMessage = Message(
            senderId: currentUserId,
            receiverId: receiverId,
            content: messageText
        )
        messageText = "" // Clear immediately for better UX
        
        Task {
            await messagingManager.sendMessage(
                content: content,
                to: receiverId,
                in: conversationId
            )
        }
    }
    
    private func loadMessages() {
        if let currentUserId = authManager.currentUser?.id {
            messagingManager.initialize(with: currentUserId)
            
            // Generate conversation ID from participants
            let sortedParticipants = conversation.participants.map { $0.uuidString }.sorted()
            conversationId = sortedParticipants.joined(separator: "_")
            
            messagingManager.loadMessages(for: conversationId)
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
    @State private var searchText = ""
    @State private var friends: [User] = [] // Would be populated from data
    @Environment(\.dismiss) var dismiss
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
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
                
                // Friends List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Demo friends
                        ForEach(0..<10) { index in
                            FriendRow(name: "Artist \(index + 1)", subtitle: "Producer") {
                                // Start conversation
                                dismiss()
                            }
                        }
                    }
                    .padding(.horizontal)
                }
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
