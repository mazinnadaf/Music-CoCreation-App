import SwiftUI

struct CreateView: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Create Your Next Hit")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(LinearGradient.primaryGradient)
                            .multilineTextAlignment(.center)
                        
                        Text("Start with a single layer and build your masterpiece. No experience needed - just describe what you hear in your head.")
                            .font(.body)
                            .foregroundColor(.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Instrument and BPM Selection
                    VStack(spacing: 16) {
                        // Instrument Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Select Instrument")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Layer.InstrumentType.allCases, id: \.self) { instrument in
                                        Button(action: {
                                            audioManager.selectedInstrument = instrument
                                        }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: instrument.icon)
                                                    .font(.title2)
                                                Text(instrument.rawValue)
                                                    .font(.caption)
                                            }
                                            .frame(width: 80, height: 80)
                                            .background(
                                                audioManager.selectedInstrument == instrument ? 
                                                LinearGradient.primaryGradient : 
                                                Color.cardBackground
                                            )
                                            .foregroundColor(
                                                audioManager.selectedInstrument == instrument ? 
                                                .white : .secondaryText
                                            )
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        audioManager.selectedInstrument == instrument ? 
                                                        Color.clear : Color.borderColor, 
                                                        lineWidth: 1
                                                    )
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                        
                        // BPM Input
                        HStack {
                            Text("BPM")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            Spacer()
                            
                            TextField("120", text: $audioManager.bpm)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.darkBackground.opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.borderColor, lineWidth: 1)
                                )
                                .foregroundColor(.primaryText)
                        }
                    }
                    .cardStyle()
                    
                    // Creation Interface
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.secondaryText)
                            Text("Describe the sound you want to create")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            Spacer()
                        }
                        
                        TextEditor(text: $audioManager.currentPrompt)
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color.darkBackground.opacity(0.5))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                            .font(.body)
                        
                        // Suggested Prompts
                        if audioManager.showSuggestion && audioManager.layers.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Try:")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                    Spacer()
                                }
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(Array(audioManager.suggestedPrompts[1...3]), id: \.self) { suggestion in
                                        Button(suggestion) {
                                            audioManager.currentPrompt = suggestion
                                            audioManager.showSuggestion = false
                                        }
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.cardBackground)
                                        .foregroundColor(.secondaryText)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.borderColor, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Guided Suggestion for Second Layer
                        if audioManager.showSuggestion && audioManager.layers.count == 1 {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(Color.primaryBlue)
                                    Text("Great start! Every song needs rhythm.")
                                        .fontWeight(.medium)
                                        .foregroundColor(Color.primaryBlue)
                                }
                                
                                Text("Try adding some drums to give your melody a foundation:")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                
                                Button(audioManager.suggestedPrompts[1]) {
                                    audioManager.currentPrompt = audioManager.suggestedPrompts[1]
                                    audioManager.showSuggestion = false
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.primaryBlue.opacity(0.1))
                                .foregroundColor(Color.primaryBlue)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primaryBlue.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding()
                            .background(Color.primaryBlue.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.primaryBlue.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Create Button
                        Button(action: audioManager.createLayer) {
                            HStack {
                                if audioManager.isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Creating your layer...")
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
                    .cardStyle()
                    
                    // Loading Layer
                    if audioManager.isGenerating {
                        AudioPlayerView(layer: nil, isLoading: true)
                    }
                    
                    // Created Layers
                    ForEach(audioManager.layers) { layer in
                        AudioPlayerView(layer: layer, isLoading: false)
                    }
                    
                    // Collaboration CTA
                    if audioManager.layers.count >= 2 {
                        CollaborationCTAView()
                    }
                }
                .padding()
            }
            .background(Color.darkBackground)
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    CreateView()
        .environmentObject(AudioManager())
}
