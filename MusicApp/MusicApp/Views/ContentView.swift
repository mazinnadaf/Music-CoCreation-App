import SwiftUI

struct ContentView: View {
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
            
            MessagesView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Messages")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(Color.purple)
    }
}

#Preview {
    ContentView()
}
