import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    
    var body: some View {
        TabView {
            CreateView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Create")
                }
                .tag(0)
            
            DiscoverView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Discover")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(Color.purple)
        .environmentObject(audioManager)
    }
}

#Preview {
    ContentView()
}
