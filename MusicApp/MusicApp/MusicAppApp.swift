import SwiftUI
import Firebase
import FirebaseCore

func configureFirebase() {
    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
        fatalError("GoogleService-Info.plist file not found")
    }
    
    guard let plist = NSDictionary(contentsOfFile: path) else {
        fatalError("Unable to read GoogleService-Info.plist")
    }
    
    guard let projectId = plist["PROJECT_ID"] as? String,
          let bundleId = plist["BUNDLE_ID"] as? String else {
        fatalError("Missing required Firebase configuration values")
    }
    
    print("Firebase configuring with Project ID: \(projectId)")
    print("Bundle ID: \(bundleId)")
    
    FirebaseApp.configure()
    
    if FirebaseApp.app() == nil {
        fatalError("Firebase failed to configure")
    }
    
    print("✅ Firebase configured successfully")
}

@main
struct MusicApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var audioManager = AudioManager()
    
    init() {
        configureFirebase()
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
    @EnvironmentObject var audioManager: AudioManager
    @State private var hasLoadedClips = false
    
    var body: some View {
        switch authManager.authState {
        case .unauthenticated, .authenticating:
            OnboardingView()
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                ))
                .onAppear {
                    hasLoadedClips = false
                }
        case .authenticated(_):
            if authManager.hasCompletedOnboarding {
                ContentView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    .onAppear {
                        if !hasLoadedClips {
                            loadUserClips()
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .userAuthenticated)) { _ in
                        if !hasLoadedClips {
                            loadUserClips()
                        }
                    }
            } else {
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
                    .onAppear {
                        hasLoadedClips = false
                    }
            }
        case .onboarding:
            OnboardingView()
                .onAppear {
                    hasLoadedClips = false
                }
        }
    }
    
    private func loadUserClips() {
        print("[App] 🔄 Loading user clips...")
        hasLoadedClips = true
        audioManager.loadUserClips { result in
            switch result {
            case .success(let clips):
                DispatchQueue.main.async {
                    audioManager.layers = clips
                    print("[App] ✅ Loaded \(clips.count) user clips")
                }
            case .failure(let error):
                print("[App] ❌ Failed to load user clips: \(error.localizedDescription)")
                hasLoadedClips = false
            }
        }
    }
}
