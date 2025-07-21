import SwiftUI

struct FriendsView: View {
    @StateObject private var friendsManager = FriendsManager()
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showAddFriend = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Friends Tab", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Requests").tag(1)
                    Text("Find").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .background(Color.cardBackground)
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    // Friends List
                    FriendsListView(friends: friendsManager.friends)
                        .tag(0)
                    
                    // Friend Requests
                    FriendRequestsView(
                        requests: friendsManager.friendRequests,
                        friendsManager: friendsManager,
                        onAccept: { request in
                            Task {
                                await friendsManager.acceptFriendRequest(request)
                            }
                        },
                        onDecline: { request in
                            Task {
                                await friendsManager.declineFriendRequest(request)
                            }
                        }
                    )
                    .tag(1)
                    
                    // Find Friends
                    FindFriendsView(
                        searchText: $searchText,
                        searchResults: friendsManager.searchResults,
                        isLoading: friendsManager.isLoading,
                        onSearch: { query in
                            Task {
                                await friendsManager.searchUsers(query: query)
                            }
                        },
                        onSendRequest: { user in
                            Task {
                                await friendsManager.sendFriendRequest(to: user)
                            }
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let currentUser = authManager.currentUser {
                    friendsManager.initialize(with: UUID(uuidString: currentUser.id) ?? UUID())
                }
            }
            .alert("Error", isPresented: .constant(friendsManager.error != nil)) {
                Button("OK") {
                    friendsManager.error = nil
                }
            } message: {
                Text(friendsManager.error ?? "")
            }
        }
    }
}

// MARK: - Friends List View
struct FriendsListView: View {
    let friends: [User]
    
    var body: some View {
        if friends.isEmpty {
            EmptyFriendsView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(friends) { friend in
                        FriendCardView(user: friend) {
                            // Navigate to friend's profile or start conversation
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Friend Requests View
struct FriendRequestsView: View {
    let requests: [FriendRequest]
    let friendsManager: FriendsManager
    let onAccept: (FriendRequest) -> Void
    let onDecline: (FriendRequest) -> Void
    
    var body: some View {
        if requests.isEmpty {
            EmptyRequestsView()
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(requests) { request in
                        FriendRequestCardView(
                            request: request,
                            friendsManager: friendsManager,
                            onAccept: { onAccept(request) },
                            onDecline: { onDecline(request) }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Find Friends View
struct FindFriendsView: View {
    @Binding var searchText: String
    let searchResults: [User]
    let isLoading: Bool
    let onSearch: (String) -> Void
    let onSendRequest: (User) -> Void
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryText)
                TextField("Search for artists...", text: $searchText)
                    .foregroundColor(.primaryText)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        onSearch(searchText)
                    }
                    .onChange(of: searchText) { newValue in
                        if newValue.count > 2 {
                            onSearch(newValue)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.secondaryText)
                    .font(.caption)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .padding(.horizontal)
            
            // Search Results
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                EmptySearchResultsView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults) { user in
                            SearchResultCardView(
                                user: user,
                                onSendRequest: { onSendRequest(user) }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onTapGesture {
            isSearchFieldFocused = false
        }
    }
}

// MARK: - Card Views
struct FriendCardView: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(user.artistName.prefix(2).uppercased())
                            .font(.headline)
                            .foregroundColor(.white)
                    )
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.artistName)
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    Text("@\(user.username)")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    if !user.bio.isEmpty {
                        Text(user.bio)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "message")
                            .foregroundColor(.primaryText)
                            .font(.title3)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "music.note")
                            .foregroundColor(.primaryText)
                            .font(.title3)
                    }
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FriendRequestCardView: View {
    let request: FriendRequest
    let friendsManager: FriendsManager
    let onAccept: () -> Void
    let onDecline: () -> Void
    @State private var senderUser: User?
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(LinearGradient.primaryGradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Text((senderUser?.artistName.prefix(2) ?? "??").uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(senderUser?.artistName ?? "Loading...")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text("@\(senderUser?.username ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text("Sent \(formatDate(request.sentAt))")
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(18)
                }
                
                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.title3)
                        .frame(width: 36, height: 36)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(18)
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .onAppear {
            Task {
                if senderUser == nil {
                    senderUser = await friendsManager.getFriendRequestSender(request)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct SearchResultCardView: View {
    let user: User
    let onSendRequest: () -> Void
    @State private var requestSent = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(LinearGradient.primaryGradient)
                .frame(width: 56, height: 56)
                .overlay(
                    Text(user.artistName.prefix(2).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.artistName)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                }
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Add Friend Button
            Button(action: {
                onSendRequest()
                requestSent = true
            }) {
                if requestSent {
                    Image(systemName: "checkmark")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.primaryText)
                        .font(.title3)
                }
            }
            .disabled(requestSent)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Empty State Views
struct EmptyFriendsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text("No friends yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("Find other artists to collaborate with")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyRequestsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text("No friend requests")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("You'll see friend requests here")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptySearchResultsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(LinearGradient.primaryGradient)
            
            Text("No results found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("Try searching with different keywords")
                .font(.body)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FriendsView()
        .environmentObject(AuthenticationManager())
}
