import SwiftUI

struct TrackCardView: View {
    let track: Track
    let isLiked: Bool
    let isPlaying: Bool
    let playbackProgress: Double  // 0.0 to 1.0
    let currentTime: String      // e.g., "1:23"
    let onLike: () -> Void
    let onPlay: () -> Void
    let onJoin: (Track) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar
                Circle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(track.avatar)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and Tags
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(track.title)
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            // Type Badge
                            HStack(spacing: 4) {
                                Image(systemName: track.type.icon)
                                    .font(.caption2)
                                Text(track.type.rawValue.capitalized)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(track.type.color.opacity(0.2))
                            .foregroundColor(track.type.color)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(track.type.color.opacity(0.3), lineWidth: 1)
                            )
                            
                            // Open Badge
                            if track.isOpen {
                                HStack(spacing: 4) {
                                    Image(systemName: "circle.fill")
                                        .font(.caption2)
                                    Text("Open")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                            }
                            
                            Spacer()
                        }
                        
                        Text("by \(track.artist) • \(track.genre) • \(track.duration)")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        if let description = track.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.primaryText.opacity(0.8))
                                .padding(.top, 2)
                        }
                    }
                    
                    // Progress bar - show when track has been played (has progress)
                    if playbackProgress > 0 || currentTime != "0:00" {
                        VStack(spacing: 4) {
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.borderColor)
                                        .frame(height: 4)
                                    
                                    // Progress
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.primaryBlue)
                                        .frame(width: geometry.size.width * playbackProgress, height: 4)
                                }
                            }
                            .frame(height: 4)
                            
                            HStack {
                                Text(currentTime)
                                    .font(.caption2)
                                    .foregroundColor(.secondaryText)
                                Spacer()
                                Text(track.duration)
                                    .font(.caption2)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                    }
                    
                    // Actions
                    HStack {
                        Button(action: onPlay) {
                            HStack(spacing: 6) {
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.caption)
                                Text(isPlaying ? "Pause" : "Play")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(LinearGradient.primaryGradient)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        if track.isOpen {
                            Button(action: { onJoin(track) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: track.type == .stem ? "waveform" : "plus")
                                        .font(.caption)
                                    Text(track.type == .stem ? "Using Stem" : "Join")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    track.type == .stem ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.primaryBlue.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) : 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.cardBackground, Color.cardBackground]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(track.type == .stem ? .white : .secondaryText)
                                .cornerRadius(8)
                                .overlay(
                                    track.type != .stem ?
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderColor, lineWidth: 1)
                                    : nil
                                )
                            }
                        }
                        
                        Spacer()
                        
                        // Stats
                        HStack(spacing: 16) {
                            Button(action: onLike) {
                                HStack(spacing: 4) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.caption)
                                        .foregroundColor(isLiked ? .red : .secondaryText)
                                    Text("\(track.likes)")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                            }
                            
                            if track.collaborators > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .font(.caption)
                                    Text("\(track.collaborators)")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondaryText)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    TrackCardView(
        track: MockData.tracks.first!,
        isLiked: false,
        isPlaying: false,
        playbackProgress: 0.0,
        currentTime: "0:00",
        onLike: {},
        onPlay: {},
        onJoin: { _ in }
    )
    .padding()
    .background(Color.darkBackground)
}
