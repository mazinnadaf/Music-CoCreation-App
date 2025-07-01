import SwiftUI

struct DiscoverView: View {
    @State private var selectedFilter: Track.TrackType? = nil
    @State private var likedTracks: Set<UUID> = []
    @State private var tracks: [Track] = MockData.tracks
    
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
                            TrackCardView(
                                track: track,
                                isLiked: likedTracks.contains(track.id),
                                onLike: { toggleLike(trackId: track.id) },
                                onPlay: { /* Handle play */ },
                                onJoin: { /* Handle join/use stem */ }
                            )
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
        }
    }
    
    private func toggleLike(trackId: UUID) {
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
                .background(isSelected ? LinearGradient.primaryGradient : Color.cardBackground.gradient)
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
