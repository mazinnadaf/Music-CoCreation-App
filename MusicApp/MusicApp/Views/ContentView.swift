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
            
            FriendsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Friends")
                }
                .tag(2)
            
            MessagesView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("Messages")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(Color.purple)
    }
}

#Preview {
    ContentView()
}
