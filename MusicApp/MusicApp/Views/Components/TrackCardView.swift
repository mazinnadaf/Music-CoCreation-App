import SwiftUI

struct TrackCardView: View {
    let track: Track
    let isLiked: Bool
    let onLike: () -> Void
    let onPlay: () -> Void
    let onJoin: () -> Void
    
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
                    
                    // Actions
                    HStack {
                        Button(action: onPlay) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                    .font(.caption)
                                Text("Play")
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
                            Button(action: onJoin) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                    Text(track.type == .collaboration ? "Join" : "Use Stem")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.cardBackground)
                                .foregroundColor(.secondaryText)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderColor, lineWidth: 1)
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
        onLike: {},
        onPlay: {},
        onJoin: {}
    )
    .padding()
    .background(Color.darkBackground)
}
