import SwiftUI

// MARK: - Profile Header
struct ProfileHeaderView: View {
    let user: User?
    @Binding var showEditProfile: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: { showEditProfile = true }) {
                    Image(systemName: "pencil")
                        .font(.title3)
                        .foregroundColor(.secondaryText)
                        .padding(8)
                        .background(Color.cardBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 16) {
                // Avatar
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(user?.artistName.prefix(2).uppercased() ?? "AR")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Name and Bio
                VStack(spacing: 8) {
                    HStack {
                        Text(user?.artistName ?? "Artist")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                        
                        if user?.isVerified == true {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    
                    if let bio = user?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                
                // Stats
                HStack(spacing: 40) {
                    StatView(value: "\(user?.stats.totalTracks ?? 0)", label: "Tracks")
                    StatView(value: "\(user?.stats.totalCollaborations ?? 0)", label: "Collabs")
                    StatView(value: "\(user?.stats.producerCredits ?? 0)", label: "Credits")
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .primaryText : .secondaryText)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.primaryPurple.opacity(0.2) : Color.clear)
            )
        }
    }
}

// MARK: - Profile Overview
struct ProfileOverviewView: View {
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Skills
            if let skills = user?.skills, !skills.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Skills")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(skills) { skill in
                            HStack {
                                Image(systemName: skill.icon)
                                    .font(.caption)
                                Text(skill.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(skill.level.rawValue)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(skill.level.color)
                                    .cornerRadius(4)
                            }
                            .padding(12)
                            .background(Color.cardBackground)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Social Links
            if let socialLinks = user?.socialLinks, !socialLinks.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connect")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    HStack(spacing: 16) {
                        ForEach(socialLinks) { link in
                            Button(action: {}) {
                                Image(systemName: link.platform.icon)
                                    .font(.title3)
                                    .foregroundColor(.secondaryText)
                                    .frame(width: 44, height: 44)
                                    .background(Color.cardBackground)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
            
            // Activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(user?.stats.streak ?? 0) day streak")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.green)
                        Text("\(user?.stats.totalPlays ?? 0) total plays")
                            .font(.body)
                            .foregroundColor(.primaryText)
                        Spacer()
                    }
                }
                .padding()
                .cardStyle()
            }
        }
    }
}

// MARK: - Profile Tracks
struct ProfileTracksView: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 16) {
            if audioManager.layers.isEmpty {
                Text("Your tracks will appear here")
                    .font(.headline)
                    .foregroundColor(.secondaryText)
                    .padding(.vertical, 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.cardBackground.opacity(0.5))
                    .cornerRadius(12)
            } else {
                ForEach(audioManager.layers) { layer in
                    TrackCardView(
                        track: Track(
                            title: layer.name,
                            artist: layer.creatorName ?? "You",
                            artistId: layer.creatorId ?? "",
                            avatar: String((layer.creatorName ?? "You").prefix(2)),
                            genre: "", // Add genre if available
                            duration: String(format: "%.0f sec", layer.duration),
                            likes: 0,
                            collaborators: 0,
                            isOpen: false,
                            type: .track,
                            description: layer.prompt,
                            layerIds: [layer.id],
                            bpm: layer.bpm
                        ),
                        isLiked: false,
                        isPlaying: false,
                        playbackProgress: 0.0,
                        currentTime: "0:00",
                        onLike: {},
                        onPlay: {},
                        onJoin: { _ in },
                        avatarImage: nil,
                        showPlayButton: false
                    )
                }
            }
        }
    }
}

// MARK: - Profile Collaborations
struct ProfileCollaborationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Your collaborations will appear here")
                .font(.headline)
                .foregroundColor(.secondaryText)
                .padding(.vertical, 60)
                .frame(maxWidth: .infinity)
                .background(Color.cardBackground.opacity(0.5))
                .cornerRadius(12)
        }
    }
}

// MARK: - Profile Badges
struct ProfileBadgesView: View {
    let user: User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let badges = user?.badges, !badges.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(badges) { badge in
                        BadgeView(badge: badge)
                    }
                }
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "trophy")
                        .font(.system(size: 60))
                        .foregroundColor(.secondaryText.opacity(0.5))
                    
                    Text("No badges yet")
                        .font(.headline)
                        .foregroundColor(.secondaryText)
                    
                    Text("Keep creating and collaborating to earn badges!")
                        .font(.body)
                        .foregroundColor(.secondaryText.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 60)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct BadgeView: View {
    let badge: Badge
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: badge.icon)
                .font(.largeTitle)
                .foregroundColor(badge.rarity.color)
                .frame(width: 60, height: 60)
                .background(badge.rarity.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(badge.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(badge.rarity.rawValue)
                    .font(.caption2)
                    .foregroundColor(badge.rarity.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    let user: User?
    @Environment(\.dismiss) var dismiss
    @State private var artistName = ""
    @State private var bio = ""
    @State private var selectedSkills: Set<Skill> = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar
                    Circle()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.borderColor, lineWidth: 2)
                        )
                    
                    // Form
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Artist Name")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            TextField("Enter artist name", text: $artistName)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bio")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            TextEditor(text: $bio)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color.cardBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderColor, lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Skills")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(Skill.presetSkills) { skill in
                                    SkillChip(
                                        skill: skill,
                                        isSelected: selectedSkills.contains(skill),
                                        onTap: {
                                            if selectedSkills.contains(skill) {
                                                selectedSkills.remove(skill)
                                            } else {
                                                selectedSkills.insert(skill)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.darkBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondaryText)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save changes
                        dismiss()
                    }
                    .foregroundColor(Color.primaryBlue)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            artistName = user?.artistName ?? ""
            bio = user?.bio ?? ""
            if let skills = user?.skills {
                selectedSkills = Set(skills)
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    SettingsRow(icon: "bell", title: "Notifications", action: {})
                    SettingsRow(icon: "lock", title: "Privacy", action: {})
                    SettingsRow(icon: "questionmark.circle", title: "Help & Support", action: {})
                }
                
                Section {
                    SettingsRow(icon: "info.circle", title: "About", action: {})
                    SettingsRow(icon: "doc.text", title: "Terms of Service", action: {})
                    SettingsRow(icon: "hand.raised", title: "Privacy Policy", action: {})
                }
                
                Section {
                    Button(action: {
                        authManager.signOut()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.primaryBlue)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondaryText)
                    .frame(width: 24)
                Text(title)
                    .foregroundColor(.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondaryText.opacity(0.5))
            }
        }
    }
}
