import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(LinearGradient.primaryGradient)
                            .frame(width: 96, height: 96)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            )
                        
                        Text("Artist Profile")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primaryText)
                        
                        Text("Your musical identity and collaboration history")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top)
                    
                    // Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ProfileStatsCard(
                            icon: "music.note",
                            title: "Top Tracks",
                            subtitle: "Coming Soon",
                            color: .primaryPurple
                        )
                        
                        ProfileStatsCard(
                            icon: "person.2.fill",
                            title: "Collaborations",
                            subtitle: "Coming Soon",
                            color: .primaryBlue
                        )
                        
                        ProfileStatsCard(
                            icon: "trophy.fill",
                            title: "Achievements",
                            subtitle: "Coming Soon",
                            color: .blue
                        )
                    }
                }
                .padding()
            }
            .background(Color.darkBackground)
            .navigationBarHidden(true)
        }
    }
}

struct ProfileStatsCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 64, height: 64)
                .background(color.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cardStyle()
    }
}

#Preview {
    ProfileView()
}
