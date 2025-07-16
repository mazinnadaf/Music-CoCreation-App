import Foundation
import SwiftUI

// MARK: - User Models
struct User: Identifiable, Codable {
    let id: UUID
    var username: String
    var artistName: String
    var bio: String
    var avatar: String? // URL or base64
    var skills: [Skill]
    var socialLinks: [SocialLink]
    var stats: UserStats
    var badges: [Badge]
    var joinedDate: Date
    var isVerified: Bool
    
    init(username: String, artistName: String) {
        self.id = UUID()
        self.username = username
        self.artistName = artistName
        self.bio = ""
        self.avatar = nil
        self.skills = []
        self.socialLinks = []
        self.stats = UserStats()
        self.badges = []
        self.joinedDate = Date()
        self.isVerified = false
    }
}

struct Skill: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let level: SkillLevel
    
    init(name: String, icon: String, level: SkillLevel) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.level = level
    }
    
    enum SkillLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        var color: Color {
            switch self {
            case .beginner: return .gray
            case .intermediate: return .blue
            case .advanced: return .purple
            case .expert: return .orange
            }
        }
    }
}

struct SocialLink: Identifiable, Codable {
    let id: UUID
    let platform: SocialPlatform
    let url: String
    
    init(platform: SocialPlatform, url: String) {
        self.id = UUID()
        self.platform = platform
        self.url = url
    }
    
    enum SocialPlatform: String, Codable, CaseIterable {
        case instagram = "Instagram"
        case tiktok = "TikTok"
        case spotify = "Spotify"
        case soundcloud = "SoundCloud"
        case youtube = "YouTube"
        case twitter = "Twitter"
        
        var icon: String {
            switch self {
            case .instagram: return "camera"
            case .tiktok: return "music.note"
            case .spotify: return "music.note.list"
            case .soundcloud: return "cloud"
            case .youtube: return "play.rectangle"
            case .twitter: return "bubble.left"
            }
        }
    }
}

struct UserStats: Codable {
    var totalTracks: Int = 0
    var totalCollaborations: Int = 0
    var totalPlays: Int = 0
    var totalLikes: Int = 0
    var producerCredits: Int = 0
    var weeklyActive: Bool = false
    var streak: Int = 0
}

struct Badge: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let earnedDate: Date
    let rarity: BadgeRarity
    
    init(name: String, description: String, icon: String, earnedDate: Date, rarity: BadgeRarity) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.icon = icon
        self.earnedDate = earnedDate
        self.rarity = rarity
    }
    
    enum BadgeRarity: String, Codable {
        case common = "Common"
        case rare = "Rare"
        case epic = "Epic"
        case legendary = "Legendary"
        
        var color: Color {
            switch self {
            case .common: return .gray
            case .rare: return .blue
            case .epic: return .purple
            case .legendary: return .orange
            }
        }
    }
}

// MARK: - Collaboration Models
struct Collaboration: Identifiable, Codable {
    let id: UUID
    let projectId: UUID
    var title: String
    var description: String
    var creator: User
    var collaborators: [User]
    var layers: [Layer]
    var genre: String
    var bpm: Int
    var key: String?
    var status: CollaborationStatus
    var createdAt: Date
    var updatedAt: Date
    var isPublic: Bool
    var maxCollaborators: Int
    
    enum CollaborationStatus: String, Codable {
        case open = "Open"
        case inProgress = "In Progress"
        case completed = "Completed"
        case published = "Published"
    }
    
    init(projectId: UUID = UUID(), title: String, description: String, creator: User, genre: String, bpm: Int, key: String? = nil, maxCollaborators: Int = 4) {
        self.id = UUID()
        self.projectId = projectId
        self.title = title
        self.description = description
        self.creator = creator
        self.collaborators = []
        self.layers = []
        self.genre = genre
        self.bpm = bpm
        self.key = key
        self.status = .open
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPublic = true
        self.maxCollaborators = maxCollaborators
    }
}

// MARK: - Band Models
struct Band: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var members: [BandMember]
    var avatar: String?
    var createdAt: Date
    var tracks: [Track]
    
    struct BandMember: Identifiable, Codable {
        let id: UUID
        let user: User
        let role: String
        let joinedAt: Date
        
        init(user: User, role: String, joinedAt: Date = Date()) {
            self.id = UUID()
            self.user = user
            self.role = role
            self.joinedAt = joinedAt
        }
    }
    
    init(name: String, description: String, members: [BandMember], avatar: String? = nil, tracks: [Track] = []) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.members = members
        self.avatar = avatar
        self.createdAt = Date()
        self.tracks = tracks
    }
}

// MARK: - Notification Models
struct AppNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let isRead: Bool
    let actionId: String? // Track ID, User ID, etc.
    
    enum NotificationType: String {
        case stemUsed = "stem_used"
        case collaborationRequest = "collab_request"
        case trackLiked = "track_liked"
        case newFollower = "new_follower"
        case bandInvite = "band_invite"
        case achievement = "achievement"
        case trending = "trending"
    }
}

// MARK: - Skills Presets
extension Skill {
    static let presetSkills: [Skill] = [
        Skill(name: "Drum Patterns", icon: "metronome", level: .intermediate),
        Skill(name: "Melodies", icon: "music.note", level: .advanced),
        Skill(name: "Basslines", icon: "waveform", level: .intermediate),
        Skill(name: "Vocals", icon: "mic", level: .beginner),
        Skill(name: "Mixing", icon: "slider.horizontal.3", level: .intermediate),
        Skill(name: "Sound Design", icon: "waveform.path.ecg", level: .advanced),
        Skill(name: "Lyrics", icon: "text.quote", level: .intermediate),
        Skill(name: "Production", icon: "dial.min", level: .expert)
    ]
}
