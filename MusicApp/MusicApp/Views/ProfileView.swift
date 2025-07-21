import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab: ProfileTab = .overview
    @State private var showEditProfile = false
    @State private var showSettings = false
    
    enum ProfileTab: String, CaseIterable {
        case overview = "Overview"
        case tracks = "Tracks"
        case collaborations = "Collabs"
        case badges = "Badges"
        
        var icon: String {
            switch self {
            case .overview: return "person.fill"
            case .tracks: return "music.note.list"
            case .collaborations: return "person.2.fill"
            case .badges: return "trophy.fill"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    ProfileHeaderView(user: authManager.currentUser, showEditProfile: $showEditProfile)
                    
                    // Tab Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 24) {
                            ForEach(ProfileTab.allCases, id: \.self) { tab in
                                TabButton(
                                    title: tab.rawValue,
                                    icon: tab.icon,
                                    isSelected: selectedTab == tab,
                                    action: { selectedTab = tab }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    
                    // Tab Content
                    Group {
                        switch selectedTab {
                        case .overview:
                            ProfileOverviewView(user: authManager.currentUser)
                        case .tracks:
                            ProfileTracksView()
                        case .collaborations:
                            ProfileCollaborationsView()
                        case .badges:
                            ProfileBadgesView(user: authManager.currentUser)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)

                    // Log Out Button
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                                .foregroundColor(.red)
                            Text("Log Out")
                                .foregroundColor(.red)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.darkBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(user: authManager.currentUser)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
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
