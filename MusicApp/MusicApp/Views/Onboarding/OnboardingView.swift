import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var audioManager = AudioManager()
    @State private var currentStep: OnboardingStep = .welcome
    @State private var artistName = ""
    @State private var selectedSkills: Set<Skill> = []
    @State private var hasCreatedFirstLayer = false
    
    enum OnboardingStep {
        case welcome
        case createFirst
        case profileSetup
    }
    
    var body: some View {
        ZStack {
            Color.darkBackground.ignoresSafeArea()
            
            switch currentStep {
            case .welcome:
                WelcomeView(onContinue: {
                    withAnimation(.spring()) {
                        currentStep = .createFirst
                    }
                })
                .environmentObject(authManager)
                
            case .createFirst:
                FirstCreationView(
                    audioManager: audioManager,
                    hasCreatedLayer: $hasCreatedFirstLayer,
                    onContinue: {
                        withAnimation(.spring()) {
                            currentStep = .profileSetup
                        }
                    }
                )
                
            case .profileSetup:
                ProfileSetupView(
                    artistName: $artistName,
                    selectedSkills: $selectedSkills,
                    onComplete: {
                        authManager.completeProfile(
                            artistName: artistName,
                            bio: nil,
                            skills: Array(selectedSkills)
                        )
                    }
                )
            }
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo/Icon
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 80))
                .foregroundStyle(LinearGradient.primaryGradient)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 16) {
                Text("Welcome to BeatSync")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Create music together, one layer at a time")
                    .font(.title3)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Social Login Options
            VStack(spacing: 12) {
                ForEach(SocialProvider.allCases, id: \.self) { provider in
                    SocialLoginButton(provider: provider) {
                        // Handle social login
                    }
                }
                
                Text("or")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .padding(.vertical, 8)
                
                Button(action: {
                    // Authenticate as guest user for demo
                    authManager.signInAsGuest()
                    onContinue()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Start Creating")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LinearGradient.primaryGradient)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - First Creation View
struct FirstCreationView: View {
    @ObservedObject var audioManager: AudioManager
    @Binding var hasCreatedLayer: Bool
    let onContinue: () -> Void
    @State private var showShareOptions = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create Your First Sound")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("Just describe what you hear in your head")
                        .font(.body)
                        .foregroundColor(.secondaryText)
                }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 48)
            
            // Creation Interface (similar to CreateView but simplified)
            VStack(spacing: 16) {
                TextEditor(text: $audioManager.currentPrompt)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding()
                    .background(Color.darkBackground.opacity(0.5))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                    .font(.body)
                
                Button(action: {
                    audioManager.createLayer()
                    hasCreatedLayer = true
                }) {
                    HStack {
                        if audioManager.isGenerating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Creating magic...")
                        } else {
                            Image(systemName: "sparkles")
                            Text("Create Layer")
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(GradientButtonStyle())
                .disabled(audioManager.currentPrompt.isEmpty || audioManager.isGenerating)
            }
            .padding(.horizontal)
            
            // Loading or Layer Display
            if audioManager.isGenerating {
                LoadingAnimationView()
                    .frame(height: 120)
                    .padding(.horizontal)
            }
            
            // Created Layers
            ForEach(audioManager.layers) { layer in
                AudioPlayerView(layer: layer, isLoading: false)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Continue Button (appears after first layer)
            if hasCreatedLayer && !audioManager.isGenerating {
                VStack(spacing: 16) {
                    Text("🎉 Amazing! You just created your first sound!")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Button(action: { showShareOptions = true }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.cardBackground)
                            .foregroundColor(.secondaryText)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                        }
                        
                        Button(action: onContinue) {
                            HStack {
                                Text("Set Up Profile")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(LinearGradient.primaryGradient)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .sheet(isPresented: $showShareOptions) {
            ShareSheet(items: ["Check out my first beat on BeatSync! 🎵"])
        }
    }
}

// MARK: - Profile Setup View
struct ProfileSetupView: View {
    @Binding var artistName: String
    @Binding var selectedSkills: Set<Skill>
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient.primaryGradient)
                
                Text("Complete Your Artist Profile")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Tell us about yourself so others can collaborate with you")
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 48)
            
            // Form
            VStack(spacing: 24) {
                // Artist Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Artist Name")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    TextField("Enter your artist name", text: $artistName)
                        .textFieldStyle(CustomTextFieldStyle())
                }
                
                // Skills
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Skills")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(Skill.presetSkills.prefix(6), id: \.id) { skill in
                            SkillChip(
                                skill: skill,
                                isSelected: selectedSkills.contains(skill),
                                onTap: {
                                    if selectedSkills.contains(skill) {
                                        selectedSkills.remove(skill)
                                    } else {
                                        selectedSkills.insert(skill)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Complete Button
            Button(action: onComplete) {
                Text("Complete Setup")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        artistName.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.3)) : AnyShapeStyle(LinearGradient.primaryGradient)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(artistName.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Supporting Views
struct SocialLoginButton: View {
    let provider: SocialProvider
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: provider.icon)
                Text("Continue with \(provider.rawValue)")
                Spacer()
            }
            .font(.headline)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(Color.cardBackground)
            .foregroundColor(.primaryText)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
    }
}

struct SkillChip: View {
    let skill: Skill
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: skill.icon)
                    .font(.caption)
                Text(skill.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(Color.cardBackground))
            .foregroundColor(isSelected ? .white : .secondaryText)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : Color.borderColor, lineWidth: 1)
            )
        }
    }
}

struct LoadingAnimationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: 4, height: 40)
                    .scaleEffect(y: isAnimating ? 1.5 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .foregroundColor(.primaryText)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager())
}
