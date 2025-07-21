import SwiftUI

struct PublishTrackSheet: View {
    @EnvironmentObject var audioManager: AudioManager
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var genre: String = ""
@State private var allowCollaboration = false
@State private var useAsStem = false
    @State private var isPublishing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Track Details")) {
                        TextField("Title", text: $title)
                        TextField("Description (optional)", text: $description)
                        TextField("Genre", text: $genre)
                    }
                    
                    Section(header: Text("Collaboration Settings")) {
VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $useAsStem) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Use as Stem")
                                        .foregroundColor(.primaryText)
                                    Text("Let others use this track as a base for their music")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                            }
                            .tint(Color.primaryBlue)
                            .onChange(of: useAsStem) { newValue in
                                if newValue { allowCollaboration = false }
                            }
                            
                            Toggle(isOn: $allowCollaboration) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Allow Collaborations")
                                        .foregroundColor(.primaryText)
                                    Text("Let others collaborate by adding layers to this track")
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                            }
                            .tint(Color.primaryBlue)
                            .onChange(of: allowCollaboration) { newValue in
                                if newValue { useAsStem = false }
                            }
                        }
                        
if useAsStem {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.purple)
                                    .font(.caption)
                                Text("Your track will appear as a stem for others to build on")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                        
                        if allowCollaboration {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.primaryBlue)
                                    .font(.caption)
                                Text("Multiple people can collaborate on this track")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                        }
                    }
                }
                .disabled(isPublishing)
                
                Button(action: publishTrack) {
                    if isPublishing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Publish")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .buttonStyle(GradientButtonStyle())
                .disabled(isPublishing || title.isEmpty || genre.isEmpty)
                .padding()
            }
            .navigationBarTitle("Publish Track", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .alert("Error Publishing Track", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func publishTrack() {
        isPublishing = true
        audioManager.postTrackToDiscover(
            title: title, 
            description: description.isEmpty ? nil : description, 
            genre: genre,
isStem: useAsStem, allowCollaboration: allowCollaboration
        ) { result in
            isPublishing = false
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

