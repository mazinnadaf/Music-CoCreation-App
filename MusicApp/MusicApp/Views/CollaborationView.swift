import SwiftUI

struct CollaborationView: View {
    let collaboration: Collaboration
    @StateObject private var audioManager = AudioManager()
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var currentPrompt = ""
    @State private var showInviteSheet = false
    @State private var showLayerOptions = false
    @State private var selectedLayer: Layer?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                CollaborationHeader(
                    collaboration: collaboration,
                    onBack: { dismiss() },
                    onInvite: { showInviteSheet = true }
                )
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Project Info
                        ProjectInfoCard(collaboration: collaboration)
                        
                        // Collaborators
                        CollaboratorsSection(collaborators: collaboration.collaborators)
                        
                        // Existing Layers
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Layers (\(collaboration.layers.count))")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                                .padding(.horizontal)
                            
                            ForEach(collaboration.layers) { layer in
                                LayerCard(
                                    layer: layer,
                                    onPlay: { /* Play layer */ },
                                    onOptions: {
                                        selectedLayer = layer
                                        showLayerOptions = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        
                        // Add Layer Section
                        VStack(spacing: 16) {
                            Text("Add Your Layer")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            TextEditor(text: $currentPrompt)
                                .frame(minHeight: 80, maxHeight: 120)
                                .padding()
                                .background(Color.darkBackground.opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderColor, lineWidth: 1)
                                )
                                .font(.body)
                                .foregroundColor(.primaryText)
                            
                            Button(action: {
                                audioManager.createLayer()
                            }) {
                                HStack {
                                    if audioManager.isGenerating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                        Text("Creating layer...")
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Add Layer")
                                    }
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(LinearGradient.primaryGradient)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(currentPrompt.isEmpty || audioManager.isGenerating)
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Spacer for bottom padding
                        Color.clear.frame(height: 40)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showInviteSheet) {
            InviteCollaboratorsSheet(collaboration: collaboration)
        }
        .sheet(isPresented: $showLayerOptions) {
            if let layer = selectedLayer {
                LayerOptionsSheet(layer: layer)
            }
        }
    }
}

// MARK: - Collaboration Header
struct CollaborationHeader: View {
    let collaboration: Collaboration
    let onBack: () -> Void
    let onInvite: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.primaryText)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(collaboration.title)
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text("\(collaboration.collaborators.count)/\(collaboration.maxCollaborators) collaborators")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            // Status Badge
            HStack(spacing: 4) {
                Image(systemName: "circle.fill")
                    .font(.caption2)
                Text(collaboration.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(for: collaboration.status).opacity(0.2))
            .foregroundColor(statusColor(for: collaboration.status))
            .cornerRadius(12)
            
            Button(action: onInvite) {
                Image(systemName: "person.badge.plus")
                    .font(.title3)
                    .foregroundColor(.primaryText)
            }
        }
        .padding()
        .background(Color.cardBackground)
    }
    
    func statusColor(for status: Collaboration.CollaborationStatus) -> Color {
        switch status {
        case .open: return .green
        case .inProgress: return .orange
        case .completed: return .blue
        case .published: return .purple
        }
    }
}

// MARK: - Project Info Card
struct ProjectInfoCard: View {
    let collaboration: Collaboration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Project Details")
                .font(.caption)
                .foregroundColor(.secondaryText)
            
            Text(collaboration.description)
                .font(.body)
                .foregroundColor(.primaryText)
            
            HStack(spacing: 24) {
                HStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.caption)
                    Text(collaboration.genre)
                        .font(.caption)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "metronome")
                        .font(.caption)
                    Text("\(collaboration.bpm) BPM")
                        .font(.caption)
                }
                
                if let key = collaboration.key {
                    HStack(spacing: 8) {
                        Image(systemName: "key")
                            .font(.caption)
                        Text(key)
                            .font(.caption)
                    }
                }
            }
            .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Collaborators Section
struct CollaboratorsSection: View {
    let collaborators: [User]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Collaborators")
                .font(.headline)
                .foregroundColor(.primaryText)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(collaborators) { user in
                        CollaboratorCard(user: user)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CollaboratorCard: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient.primaryGradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(user.artistName.prefix(2)).uppercased())
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            Text(user.artistName)
                .font(.caption)
                .foregroundColor(.primaryText)
                .lineLimit(1)
            
            if !user.skills.isEmpty {
                Text(user.skills.first?.name ?? "")
                    .font(.caption2)
                    .foregroundColor(.secondaryText)
                    .lineLimit(1)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Layer Card
struct LayerCard: View {
    let layer: Layer
    let onPlay: () -> Void
    let onOptions: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Play Button
            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(LinearGradient.primaryGradient)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(layer.name)
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Text("by \(layer.creatorName ?? "Unknown") • \(layer.instrument.rawValue)")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Button(action: onOptions) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondaryText)
            }
        }
        .padding()
        .background(Color.darkBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Invite Collaborators Sheet
struct InviteCollaboratorsSheet: View {
    let collaboration: Collaboration
    @State private var searchText = ""
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
                    VStack(spacing: 12) {
                        // This would normally show actual friends
                        ForEach(0..<5) { index in
                            HStack {
                                Circle()
                                    .fill(LinearGradient.primaryGradient)
                                    .frame(width: 48, height: 48)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Artist \(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.primaryText)
                                    
                                    Text("Producer • Vocalist")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                                
                                Spacer()
                                
                                Button("Invite") {
                                    // Send invite
                                }
                                .font(.caption)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(LinearGradient.primaryGradient)
                                .foregroundColor(.white)
                                .cornerRadius(20)
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .background(Color.darkBackground.ignoresSafeArea())
            .navigationTitle("Invite Collaborators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Layer Options Sheet
struct LayerOptionsSheet: View {
    let layer: Layer
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 20)
            
            // Options
            VStack(spacing: 0) {
                OptionRow(icon: "square.and.arrow.down", title: "Download", action: {})
                OptionRow(icon: "waveform", title: "Use as Stem", action: {})
                OptionRow(icon: "slider.horizontal.3", title: "Mix Settings", action: {})
                OptionRow(icon: "trash", title: "Remove", isDestructive: true, action: {})
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .ignoresSafeArea(.container, edges: .bottom)
    }
}

struct OptionRow: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                
                Spacer()
            }
            .foregroundColor(isDestructive ? .red : .primaryText)
            .padding()
        }
        
        Divider()
            .background(Color.borderColor)
    }
}

// Helper extension for corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    CollaborationView(
        collaboration: Collaboration(
            title: "Summer Vibes",
            description: "Looking for vocalists and synth players to complete this chill summer track",
            creator: User(username: "demo", artistName: "Demo Artist"),
            genre: "Lo-fi Hip Hop",
            bpm: 85,
            key: "C Major"
        )
    )
    .environmentObject(SupabaseManager.shared)
}
