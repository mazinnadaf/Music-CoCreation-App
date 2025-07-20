import Foundation
import Supabase

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var authError: String?
    @Published var isLoading = false
    
    private let client: SupabaseClient
    
    init() {
        guard SupabaseConfig.isConfigured else {
            fatalError("⚠️ Supabase not configured. Please update SupabaseConfig.swift with your project credentials.")
        }
        
        client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        // Check for existing session
        Task {
            await checkSession()
        }
    }
    
    private func checkSession() async {
        do {
            let session = try await client.auth.session
            let user = session.user
            await handleAuthSuccess(user)
        } catch {
            print("No existing session")
        }
    }
    
    // MARK: - Authentication Methods
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            await handleAuthSuccess(session.user)
        } catch {
            authError = error.localizedDescription
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, artistName: String) async throws {
        isLoading = true
        authError = nil
        
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["artist_name": .string(artistName)]
            )
            
            let user = response.user
            await handleAuthSuccess(user)
            
        } catch {
            authError = error.localizedDescription
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async throws {
    }
    
    func signOut() async throws {
        isLoading = true
        
        do {
            try await client.auth.signOut()
        } catch {
            print("Error signing out: \(error)")
        }
        
        // Clear local state regardless of server response
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.set(false, forKey: "isAuthenticated")
        isLoading = false
    }
    
    // MARK: - Collaboration Methods
    
    func createCollaboration(title: String, description: String, genreId: String) async throws -> String {
        let collaboration = [
            "title": title,
            "description": description,
            "creator_id": currentUser?.id.uuidString ?? "",
            "genre": genreId
        ]
        
        let response = try await client
            .from("collaborations")
            .insert(collaboration)
            .execute()
        
        guard let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]], let first = data.first else {
            throw SupabaseError.invalidData
        }
        
        return first["id"] as! String
    }

    func fetchCollaborations() async throws -> [[String: Any]] {
        let response = try await client
            .from("collaborations")
            .select()
            .execute()
        
        return try JSONSerialization.jsonObject(with: response.data) as! [[String: Any]]
    }
    
    // MARK: - Track Methods
    
    private struct TrackPayload: Encodable {
        let user_id: String
        let layer_id: String
        let track_url: String
        let title: String?
        let collaboration_id: String?
        let metadata: String?
    }

    func saveTrack(layerId: String, trackUrl: String, collaborationId: String?, metadata: [String: Any]) async throws {
        guard let currentUserId = currentUser?.id.uuidString else {
            print("[Supabase] Error: No current user when saving track")
            throw SupabaseError.authRequired
        }

        print("[Supabase] Saving track with:")
        print("[Supabase]   - User ID: \(currentUserId)")
        print("[Supabase]   - Layer ID: \(layerId)")
        print("[Supabase]   - Track URL: \(trackUrl)")
        print("[Supabase]   - Collaboration ID: \(collaborationId ?? "nil")")
        print("[Supabase]   - Metadata: \(metadata)")

        let metadataAsData = try JSONSerialization.data(withJSONObject: metadata, options: [])
        let metadataAsString = String(data: metadataAsData, encoding: .utf8)
        
        // Extract title from metadata if available
        let title = metadata["prompt"] as? String ?? "Untitled Track"
        
        let track = TrackPayload(
            user_id: currentUserId,
            layer_id: layerId,
            track_url: trackUrl,
            title: title,
            collaboration_id: collaborationId,
            metadata: metadataAsString
        )

        do {
            print("[Supabase] Attempting to insert track with payload:")
            if let trackData = try? JSONEncoder().encode(track),
               let trackJSON = String(data: trackData, encoding: .utf8) {
                print("[Supabase] Track JSON: \(trackJSON)")
            }
            
            let response = try await client
                .from("tracks")
                .insert(track)
                .execute()
            
            print("[Supabase] Track saved successfully")
            print("[Supabase] Response status: \(response.status)")
            print("[Supabase] Response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")
            
            // Try to decode the response to see what was actually saved
            if let savedTracks = try? JSONSerialization.jsonObject(with: response.data) as? [[String: Any]],
               let firstTrack = savedTracks.first {
                print("[Supabase] Saved track ID: \(firstTrack["id"] ?? "unknown")")
            }
        } catch {
            print("[Supabase] ❌ Error saving track: \(error)")
            print("[Supabase] Error type: \(type(of: error))")
            print("[Supabase] Error details: \(error.localizedDescription)")
            
            // Check if it's a Supabase-specific error
            if let supabaseError = error as? PostgrestError {
                print("[Supabase] PostgrestError code: \(supabaseError.code)")
                print("[Supabase] PostgrestError message: \(supabaseError.message)")
                print("[Supabase] PostgrestError hint: \(supabaseError.hint)")
            }
            
            throw error
        }
    }

    func fetchUserTracks() async throws -> [[String: Any]] {
        let response = try await client
            .from("tracks")
            .select()
            .eq("user_id", value: currentUser?.id.uuidString ?? "")
            .execute()
        
        return try JSONSerialization.jsonObject(with: response.data) as! [[String: Any]]
    }
    
    // MARK: - Messaging Methods
    
    private struct MessagePayload: Encodable {
        let sender_id: String
        let receiver_id: String
        let content: String
    }

    func sendMessage(receiverId: String, content: String) async throws -> String {
        guard let currentUserId = currentUser?.id.uuidString else {
            throw SupabaseError.authRequired
        }

        let message = MessagePayload(
            sender_id: currentUserId,
            receiver_id: receiverId,
            content: content
        )
        
        let response = try await client
            .from("messages")
            .insert(message)
            .execute()
        
        guard let data = try JSONSerialization.jsonObject(with: response.data) as? [[String: Any]], let first = data.first else {
            throw SupabaseError.invalidData
        }
        
        return first["id"] as! String
    }
    
    func fetchConversations() async throws -> [[String: Any]] {
        let response = try await client
            .from("conversations")
            .select()
            .or("user1_id.eq.\(currentUser?.id.uuidString ?? ""),user2_id.eq.\(currentUser?.id.uuidString ?? "")")
            .execute()
        
        return try JSONSerialization.jsonObject(with: response.data) as! [[String: Any]]
    }
    
    func fetchMessages(conversationId: String) async throws -> [[String: Any]] {
        let response = try await client
            .from("messages")
            .select()
            .eq("conversation_id", value: conversationId)
            .order("created_at")
            .execute()
        
        return try JSONSerialization.jsonObject(with: response.data) as! [[String: Any]]
    }
    
    // MARK: - Friends Methods
    
    private struct FriendRequestPayload: Encodable {
        let from_user_id: String
        let to_user_id: String
        let status: String
    }

    func sendFriendRequest(toUserId: String) async throws {
        guard let currentUserId = currentUser?.id.uuidString else {
            throw SupabaseError.authRequired
        }

        let request = FriendRequestPayload(
            from_user_id: currentUserId,
            to_user_id: toUserId,
            status: "pending"
        )
        
        try await client
            .from("friend_requests")
            .insert(request)
            .execute()
    }
    
    func fetchFriends() async throws -> [[String: Any]] {
        let response = try await client
            .from("friendships")
            .select()
            .or("user_id.eq.\(currentUser?.id.uuidString ?? ""),friend_id.eq.\(currentUser?.id.uuidString ?? "")")
            .execute()
        
        return try JSONSerialization.jsonObject(with: response.data) as! [[String: Any]]
    }
    
    // MARK: - Storage Methods
    
    func uploadAudioFile(data: Data, fileName: String) async throws -> String {
        guard let currentUserId = currentUser?.id.uuidString else {
            throw SupabaseError.authRequired
        }
        
        let filePath = "\(currentUserId)/\(fileName)"
        
        _ = try await client.storage
            .from("audio-files")
            .upload(
                filePath,
                data: data,
                options: FileOptions()
            )
        
        let response = try await client.storage
            .from("audio-files")
            .createSignedURL(path: filePath, expiresIn: 3600)
        
        return response.absoluteString
    }
    
    // MARK: - Helper Methods
    
    private func handleAuthSuccess(_ user: Supabase.User) async {
        // Fetch user profile from database
        do {
            if let userProfile = try await fetchUser(userId: user.id) {
                currentUser = userProfile
                print("[Auth] User profile loaded successfully: \(currentUser?.username ?? "")")
            } else {
                print("[Auth] User profile not found, will be created by database trigger")
                // Create a temporary user object while the database trigger creates the profile
                let email = user.email ?? ""
                let username = email.components(separatedBy: "@").first ?? "user"
                let artistName = user.userMetadata["artist_name"]?.stringValue ?? username.capitalized
                
                currentUser = User(
                    id: user.id,
                    username: username,
                    artistName: artistName,
                    bio: "",
                    skills: []
                )
                
                // Try to fetch the profile again after a short delay (to let the trigger complete)
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    if let updatedProfile = try? await fetchUser(userId: user.id) {
                        await MainActor.run {
                            self.currentUser = updatedProfile
                            print("[Auth] User profile loaded after trigger creation")
                        }
                    }
                }
            }
        } catch {
            print("[Auth] Non-critical error loading user profile: \(error.localizedDescription)")
            // Don't let this error prevent login - create a temporary user object
            let email = user.email ?? ""
            let username = email.components(separatedBy: "@").first ?? "user"
            currentUser = User(
                id: user.id,
                username: username,
                artistName: username.capitalized,
                bio: "",
                skills: []
            )
        }

        isAuthenticated = true
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
    }
    
    private func fetchUser(userId: UUID) async throws -> User? {
        let response = try await client
            .from("users")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
        
        let data = response.data
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let userData = try decoder.decode(UserData.self, from: data)
            return User(
                id: userData.id,
                username: userData.email.components(separatedBy: "@").first ?? "user",
                artistName: userData.artistName,
                bio: userData.bio ?? "",
                skills: []
            )
        } catch {
            print("[Auth] Error decoding user data: \(error)")
            return nil
        }
    }
    
    // Note: User profile creation is now handled by database trigger on auth.users insert
    // This ensures profile creation doesn't block the signup process
}

// Helper struct for decoding user data from users table
struct UserData: Codable {
    let id: UUID
    let artistName: String
    let bio: String?
    let email: String
    let profileImageUrl: String?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle UUID from string
        let idString = try container.decode(String.self, forKey: .id)
        guard let uuid = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string")
        }
        self.id = uuid
        
        self.artistName = try container.decode(String.self, forKey: .artistName)
        self.bio = try container.decodeIfPresent(String.self, forKey: .bio)
        self.email = try container.decode(String.self, forKey: .email)
        self.profileImageUrl = try container.decodeIfPresent(String.self, forKey: .profileImageUrl)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case artistName = "artist_name"
        case bio
        case email
        case profileImageUrl = "profile_image_url"
    }
}

enum SupabaseError: LocalizedError {
    case authRequired
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .authRequired:
            return "Authentication required"
        case .invalidData:
            return "Invalid data format"
        }
    }
}
