import SwiftUI

@main
struct SyncFlowApp: App {
@StateObject private var supabase = SupabaseManager.shared
    @StateObject private var audioManager = AudioManager()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(supabase)
                .environmentObject(audioManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var supabase: SupabaseManager

    var body: some View {
        if supabase.isAuthenticated {
            ContentView()
        } else {
            AuthView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        }
    }
}
