import SwiftUI
import Firebase

@main
struct SyncFlowApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var audioManager = AudioManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(audioManager)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        switch authManager.authState {
        case .unauthenticated, .authenticating:
            OnboardingView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
        case .authenticated(_):
            if authManager.hasCompletedOnboarding {
                ContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        case .onboarding:
            OnboardingView()
        }
    }
}
