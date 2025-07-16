import SwiftUI

struct MessagesView: View {
    @State private var conversations: [Conversation] = []
    @State private var selectedConversation: Conversation?
    @State private var showNewMessage = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.darkBackground.ignoresSafeArea()
                
                if conversations.isEmpty {
                    EmptyMessagesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(conversations) { conversation in
                                ConversationRow(
                                    conversation: conversation,
                                    currentUserId: authManager.currentUser?.id ?? UUID()
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
    let currentUserId: UUID
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
    @State private var messages: [Message] = []
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    isFromCurrentUser: message.senderId == authManager.currentUser?.id
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .background(Color.darkBackground)
                    .onAppear {
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                
                // Message Input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                        .background(Color.cardBackground)
                        .cornerRadius(20)
                        .foregroundColor(.primaryText)
                    
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
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "phone")
                        }
                        Button(action: {}) {
                            Image(systemName: "video")
                        }
                    }
                }
            }
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func sendMessage() {
        guard let currentUserId = authManager.currentUser?.id,
              !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let newMessage = Message(
            senderId: currentUserId,
            receiverId: conversation.participants.first { $0 != currentUserId } ?? UUID(),
            content: messageText
        )
        
        messages.append(newMessage)
        messageText = ""
    }
    
    private func loadMessages() {
        messages = conversation.messages
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
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondaryText)
                    TextField("Search friends...", text: $searchText)
                        .foregroundColor(.primaryText)
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
