import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var supabase: SupabaseManager
    @State private var selectedTab: ProfileTab = .overview
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showLogoutAlert = false
    @State private var isLoggingOut = false
    
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
                    // Header with Settings and Logout
                    HStack {
                        Spacer()
                        
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
                                .foregroundColor(.secondaryText)
                        }
                        
                        Button(action: { showLogoutAlert = true }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    
                    // Profile Header
                    ProfileHeaderView(user: supabase.currentUser, showEditProfile: $showEditProfile)
                    
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
                            ProfileOverviewView(user: supabase.currentUser)
                        case .tracks:
                            ProfileTracksView()
                        case .collaborations:
                            ProfileCollaborationsView()
                        case .badges:
                            ProfileBadgesView(user: supabase.currentUser)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.darkBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(user: supabase.currentUser)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    handleLogout()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .overlay {
                if isLoggingOut {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Signing out...")
                                .padding()
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                        }
                }
            }
        }
    }
    
    private func handleLogout() {
        isLoggingOut = true
        
        Task {
            do {
                try await supabase.signOut()
            } catch {
                print("Error signing out: \(error)")
            }
            
            await MainActor.run {
                isLoggingOut = false
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
