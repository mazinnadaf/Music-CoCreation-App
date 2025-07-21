import SwiftUI

struct StemCreationView: View {
    let originalTrack: Track
    @ObservedObject var audioManager: AudioManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var showPublishSheet = false
    @State private var showMessageSheet = false
    @State private var trackTitle = ""
    @State private var trackDescription = ""
    @State private var selectedGenre = "Electronic"
    @State private var messageToAuthor = ""
    @FocusState private var isTextFieldFocused: Bool
    
    let genres = ["Electronic", "Hip Hop", "Rock", "Pop", "Jazz", "Classical", "R&B", "Country"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.primaryText)
                            }
                            
                            Spacer()
                            
                            Text("Using Stem")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Building on: \(originalTrack.title)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("by \(originalTrack.artist) • \(originalTrack.genre) • \(originalTrack.bpm) BPM")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Original Stem Layers (Read-only)
                    if !audioManager.layers.filter({ originalTrack.layerIds.contains($0.id) }).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Original Stem Layers")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                                .padding(.horizontal)
                            
                            ForEach($audioManager.layers) { $layer in
                                if originalTrack.layerIds.contains(layer.id) {
                                    LayerControlView(
                                        layer: $layer,
                                        audioManager: audioManager
                                    )
                                    .padding(.horizontal)
                                    .disabled(true) // Make original layers read-only
                                    .opacity(0.8)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Creation Interface (same as CreateView)
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.secondaryText)
                            Text("Add your own layers")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
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
                            .foregroundColor(.primaryText)
                            .focused($isTextFieldFocused)
                            .padding(.horizontal)
                        
                        Button(action: audioManager.createLayer) {
                            HStack {
                                if audioManager.isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Creating layer...")
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Layer")
                                }
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: audioManager.currentPrompt.isEmpty ? 
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.3)] : 
                                        [Color.primaryPurple, Color.primaryBlue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(audioManager.currentPrompt.isEmpty || audioManager.isGenerating)
                        }
                        .padding(.horizontal)
                    }
                    .cardStyle()
                    
                    // Your Added Layers
                    if !audioManager.layers.filter({ !originalTrack.layerIds.contains($0.id) }).isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Layers")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                                .padding(.horizontal)
                            
                            ForEach($audioManager.layers) { $layer in
                                if !originalTrack.layerIds.contains(layer.id) {
                                    LayerControlView(
                                        layer: $layer,
                                        audioManager: audioManager
                                    )
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Playback Controls
                    HStack(spacing: 32) {
                        Button(action: { audioManager.playAllLayers() }) {
                            VStack {
                                Image(systemName: "play.fill")
                                    .font(.title)
                                Text("Play All")
                                    .font(.caption)
                            }
                            .foregroundColor(.primaryBlue)
                        }
                        
                        Button(action: { audioManager.stopAllLayers() }) {
                            VStack {
                                Image(systemName: "stop.fill")
                                    .font(.title)
                                Text("Stop All")
                                    .font(.caption)
                            }
                            .foregroundColor(.primaryBlue)
                        }
                    }
                    .padding()
                    
                    // Publish Button at the bottom
                    VStack(spacing: 16) {
                        Button(action: {
                            showPublishSheet = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("Publish Remix")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: !audioManager.layers.filter({ !originalTrack.layerIds.contains($0.id) }).isEmpty ? 
                                        [Color.primaryPurple, Color.primaryBlue] : 
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .disabled(audioManager.layers.filter({ !originalTrack.layerIds.contains($0.id) }).isEmpty)
                        
                        if audioManager.layers.filter({ !originalTrack.layerIds.contains($0.id) }).isEmpty {
                            Text("Add at least one layer to publish your remix")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            .background(Color.darkBackground)
            .navigationBarHidden(true)
            .sheet(isPresented: $showPublishSheet) {
                PublishStemRemixView(
                    originalTrack: originalTrack,
                    audioManager: audioManager,
                    onPublish: { title, description, genre in
                        trackTitle = title
                        trackDescription = description
                        selectedGenre = genre
                        showPublishSheet = false
                        showMessageSheet = true
                    }
                )
            }
            .sheet(isPresented: $showMessageSheet) {
                MessageToAuthorView(
                    originalTrack: originalTrack,
                    trackTitle: trackTitle,
                    onSend: { message in
                        messageToAuthor = message
                        // Send message and publish track
                        publishRemix()
                        showMessageSheet = false
                        dismiss()
                    }
                )
            }
        }
    }
    
    private func playAll() {
        audioManager.playAllLayers()
    }
    
    private func pauseAll() {
        audioManager.stopAllLayers()
    }
    
    private func publishRemix() {
        // Publish the remix track
        audioManager.postTrackToDiscover(
            title: trackTitle,
            description: trackDescription,
            genre: selectedGenre,
            isStem: false,
            allowCollaboration: false
        ) { result in
            switch result {
            case .success(let track):
                print("[StemCreation] Successfully published remix: \(track.title)")
                // Send notification/message to original author
                sendMessageToAuthor()
            case .failure(let error):
                print("[StemCreation] Failed to publish remix: \(error)")
            }
        }
    }
    
    private func sendMessageToAuthor() {
        // In a real app, this would send a notification/message to the original author
        print("[StemCreation] Message sent to \(originalTrack.artist): \(messageToAuthor)")
    }
}

// MARK: - Publish Stem Remix View
struct PublishStemRemixView: View {
    let originalTrack: Track
    @ObservedObject var audioManager: AudioManager
    let onPublish: (String, String, String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedGenre = "Electronic"
    
    let genres = ["Electronic", "Hip Hop", "Rock", "Pop", "Jazz", "Classical", "R&B", "Country"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Track Details")) {
                    TextField("Track Title", text: $title)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Genre", selection: $selectedGenre) {
                        ForEach(genres, id: \.self) { genre in
                            Text(genre).tag(genre)
                        }
                    }
                }
                
                Section(header: Text("Attribution")) {
                    HStack {
                        Text("Original Stem:")
                            .foregroundColor(.secondaryText)
                        Text(originalTrack.title)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Original Artist:")
                            .foregroundColor(.secondaryText)
                        Text(originalTrack.artist)
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("Publish Remix")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Next") {
                    onPublish(title, description, selectedGenre)
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

// MARK: - Message to Author View
struct MessageToAuthorView: View {
    let originalTrack: Track
    let trackTitle: String
    let onSend: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var message = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Send a message to \(originalTrack.artist)")
                    .font(.headline)
                    .padding(.horizontal)
                
                Text("Let them know about your remix!")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .padding(.horizontal)
                
                TextEditor(text: $message)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .frame(minHeight: 150)
                
                // Suggested message
                if message.isEmpty {
                    Button(action: {
                        message = "Hey \(originalTrack.artist)! I just created a remix of your stem '\(originalTrack.title)' called '\(trackTitle)'. I'd love for you to check it out!"
                    }) {
                        Text("Use suggested message")
                            .font(.caption)
                            .foregroundColor(.primaryBlue)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Message Author")
            .navigationBarItems(
                leading: Button("Skip") {
                    onSend("")
                },
                trailing: Button("Send") {
                    onSend(message)
                }
                .fontWeight(.semibold)
                .disabled(message.isEmpty)
            )
        }
    }
}

struct StemCreationView_Previews: PreviewProvider {
    static var previews: some View {
        StemCreationView(
            originalTrack: Track(
                title: "Example Track",
                artist: "Example Artist",
                artistId: "",
                avatar: "",
                genre: "Rock",
                duration: "3:45",
                likes: 99,
                collaborators: 1,
                isOpen: true,
                type: .stem,
                description: "An example track",
                layerIds: [],
                bpm: 120
            ),
            audioManager: AudioManager()
        )
        .environmentObject(AuthenticationManager())
    }
}
