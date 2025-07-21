import Foundation
import SwiftUI
import Combine

class MessagingManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentMessages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let firebaseManager = FirebaseManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var currentUserId: String?
    private var currentConversationId: String?
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        firebaseManager.$conversations
            .assign(to: \.conversations, on: self)
            .store(in: &cancellables)
    }
    
    func initialize(with userId: String) {
        self.currentUserId = userId
        loadConversations()
    }
    
    func loadConversations() {
        guard let userId = currentUserId else { return }
        firebaseManager.loadConversations(for: userId)
    }
    
    func startConversation(with friendId: String) async -> String? {
        guard let currentUserId = currentUserId else { return nil }
        
        do {
            let conversationId = try await firebaseManager.createOrGetConversation(
                between: currentUserId,
                and: friendId
            )
            return conversationId
        } catch {
            await MainActor.run {
                self.error = "Failed to start conversation: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    func loadMessages(for conversationId: String) {
        self.currentConversationId = conversationId
        
        firebaseManager.loadMessages(for: conversationId)
            .receive(on: DispatchQueue.main)
            .sink { messages in
                self.currentMessages = messages
            }
            .store(in: &cancellables)
    }
    
    func sendMessage(content: String, to receiverId: String, in conversationId: String) async {
        guard let currentUserId = currentUserId else { return }
        
        let message = Message(
            senderId: currentUserId,
            receiverId: receiverId,
            content: content
        )
        
        do {
            try await firebaseManager.sendMessage(message, to: conversationId)
        } catch {
            await MainActor.run {
                self.error = "Failed to send message: \(error.localizedDescription)"
            }
        }
    }
    
    func markMessagesAsRead(in conversationId: String) async {
        guard let currentUserId = currentUserId else { return }
        
        do {
            try await firebaseManager.markMessagesAsRead(in: conversationId, for: currentUserId)
        } catch {
            await MainActor.run {
                self.error = "Failed to mark messages as read: \(error.localizedDescription)"
            }
        }
    }
    
    func getOtherParticipant(in conversation: Conversation) -> String? {
        return conversation.participants.first { $0 != currentUserId }
    }
    
    func clearCurrentMessages() {
        currentMessages = []
        currentConversationId = nil
        
        // Cancel any existing message listeners
        cancellables.removeAll()
        setupBindings()
    }
}
