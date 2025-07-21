import SwiftUI

struct DiscoverView: View {
    @State private var selectedFilter: Track.TrackType? = nil
    @State private var likedTracks: Set<String> = []
    @State private var tracks: [Track] = MockData.tracks
    @State private var selectedTrack: Track?
    @State private var showCollaborationView = false
    @State private var isLoadingTracks = false
    @State private var currentlyPlayingTrackId: String? = nil
    @State private var showJoinError = false
    @State private var joinErrorMessage = ""
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var audioManager = AudioManager()
    
    var filteredTracks: [Track] {
        if let filter = selectedFilter {
            return tracks.filter { $0.type == filter }
        }
        return tracks
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Image("sona-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Discover")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Find your next collaboration or inspiration")
                                .font(.body)
                                .foregroundColor(.secondaryText)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(Color.primaryBlue)
                            Text("Trending Now")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.primaryBlue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Filters
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All",
                                isSelected: selectedFilter == nil,
                                action: { selectedFilter = nil }
                            )
                            
                            ForEach(Track.TrackType.allCases, id: \.self) { type in
                                FilterButton(
                                    title: type.rawValue.capitalized + "s",
                                    isSelected: selectedFilter == type,
                                    action: { selectedFilter = type }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Feed
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTracks) { track in
                            trackCard(for: track)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Load More
                    Button("Load More Tracks") {
                        // Handle load more
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.cardBackground)
                    .foregroundColor(.secondaryText)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color.darkBackground)
            .navigationBarHidden(true)
            .onAppear {
                loadTracksFromFirebase()
            }
            .sheet(isPresented: $showCollaborationView) {
                if let track = selectedTrack {
                    // Create a collaboration from the track
                    CollaborationView(
                        collaboration: Collaboration(
                            title: track.title,
                            description: track.description ?? "Join this collaboration to add your unique touch!",
                            creator: User(username: "creator", artistName: track.artist),
                            genre: track.genre,
                            bpm: track.bpm,
                            key: track.key
                        )
                    )
                    .environmentObject(authManager)
                }
            }
            .alert("Join Failed", isPresented: $showJoinError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(joinErrorMessage)
            }
        }
    }
    
    private func toggleLike(trackId: String) {
        if likedTracks.contains(trackId) {
            likedTracks.remove(trackId)
            if let index = tracks.firstIndex(where: { $0.id == trackId }) {
                tracks[index].likes -= 1
            }
        } else {
            likedTracks.insert(trackId)
            if let index = tracks.firstIndex(where: { $0.id == trackId }) {
                tracks[index].likes += 1
            }
        }
    }
    
    private func loadTracksFromFirebase() {
        isLoadingTracks = true
        audioManager.loadDiscoverTracks { result in
            isLoadingTracks = false
            switch result {
            case .success(let loadedTracks):
                // Combine Firebase tracks with mock data (optional)
                self.tracks = loadedTracks + MockData.tracks
            case .failure(let error):
                print("Failed to load tracks from Firebase: \(error)")
                // Fall back to mock data
                self.tracks = MockData.tracks
            }
        }
    }
    
    private func playTrack(_ track: Track) {
        // If same track is playing, toggle pause/resume
        if currentlyPlayingTrackId == track.id {
            // Check if any layers from this track are loaded
            let hasLoadedLayers = audioManager.layers.contains { layer in
                track.layerIds.contains(layer.id)
            }
            
            if hasLoadedLayers {
                // Track is loaded, just toggle playback
                let isAnyLayerPlaying = audioManager.layers.contains { layer in
                    track.layerIds.contains(layer.id) && layer.isPlaying
                }
                
                if isAnyLayerPlaying {
                    // Pause all layers from this track
                    for layer in audioManager.layers where track.layerIds.contains(layer.id) {
                        if layer.isPlaying {
                            audioManager.toggleLayerPlayback(layerId: layer.id)
                        }
                    }
                } else {
                    // Resume all layers from this track
                    for layer in audioManager.layers where track.layerIds.contains(layer.id) {
                        if !layer.isPlaying {
                            audioManager.toggleLayerPlayback(layerId: layer.id)
                        }
                    }
                }
                return
            }
        }
        
        // Different track or no track loaded - stop current and play new
        if currentlyPlayingTrackId != nil {
            audioManager.stopAllLayers()
        }
        
        // Set as currently playing
        currentlyPlayingTrackId = track.id
        
        // Play the track
        audioManager.playTrack(track) { result in
            switch result {
            case .success:
                print("[Discover] Successfully playing track: \(track.title)")
            case .failure(let error):
                print("[Discover] Failed to play track: \(error)")
                currentlyPlayingTrackId = nil
            }
        }
    }
    
    private func trackCard(for track: Track) -> some View {
        let isActuallyPlaying = currentlyPlayingTrackId == track.id && 
            audioManager.layers.contains { layer in
                track.layerIds.contains(layer.id) && layer.isPlaying
            }
        
        return TrackCardView(
            track: track,
            isLiked: likedTracks.contains(track.id),
            isPlaying: isActuallyPlaying,
            playbackProgress: audioManager.playbackProgress(for: track),
            currentTime: audioManager.currentTime(for: track),
            onLike: { toggleLike(trackId: track.id) },
            onPlay: { playTrack(track) },
            onJoin: { _ in joinTrackAsCollaborator(track) }
        )
        .overlay(
            // Playing indicator - show when track is loaded (playing or paused)
            currentlyPlayingTrackId == track.id ?
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primaryBlue, lineWidth: 2)
                .animation(.easeInOut(duration: 0.3), value: currentlyPlayingTrackId)
            : nil
        )
    }
    
    private func joinTrackAsCollaborator(_ track: Track) {
        // Check if track is open for collaboration
        guard track.isOpen else {
            joinErrorMessage = "This track is not open for collaboration."
            showJoinError = true
            return
        }
        
        // Join as collaborator
        audioManager.joinTrackAsCollaborator(track) { result in
            switch result {
            case .success:
                print("[Discover] Successfully joined track as collaborator")
                // Navigate to collaboration view
                selectedTrack = track
                showCollaborationView = true
                
                // Update local track state
                if let index = tracks.firstIndex(where: { $0.id == track.id }) {
                    tracks[index].collaborators += 1
                    // If track reaches max collaborators, close it
                    if tracks[index].collaborators >= 2 {
                        tracks[index].isOpen = false
                    }
                }
                
            case .failure(let error):
                print("[Discover] Failed to join track: \(error)")
                joinErrorMessage = error.localizedDescription
                showJoinError = true
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient.primaryGradient
                        } else {
                            Color.cardBackground
                        }
                    }
                )
                .foregroundColor(isSelected ? .white : .secondaryText)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.borderColor, lineWidth: 1)
                )
        }
    }
}

#Preview {
    DiscoverView()
}
