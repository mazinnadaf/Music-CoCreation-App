import SwiftUI
import Combine

struct Layer: Identifiable, Codable {
    let id: UUID
    let name: String
    let prompt: String
    var isPlaying: Bool = false
    let duration: TimeInterval = 30.0
    var currentTime: TimeInterval = 0.0
    let waveformData: [Float]
    let creatorId: UUID?
    let creatorName: String?
    let bpm: Int
    let key: String?
    let instrument: InstrumentType
    var volume: Float = 0.8
    var isMuted: Bool = false
    var isSolo: Bool = false
    let createdAt: Date
    var isPublic: Bool = false
    var useCount: Int = 0
    
    enum InstrumentType: String, Codable, CaseIterable {
        case drums = "Drums"
        case bass = "Bass"
        case melody = "Melody"
        case vocals = "Vocals"
        case pads = "Pads"
        case fx = "FX"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .drums: return "metronome"
            case .bass: return "waveform"
            case .melody: return "music.note"
            case .vocals: return "mic"
            case .pads: return "pianokeys"
            case .fx: return "sparkles"
            case .other: return "music.quarternote.3"
            }
        }
    }
    
    init(name: String, prompt: String, bpm: Int = 120, instrument: InstrumentType = .other, creatorId: UUID? = nil, creatorName: String? = nil) {
        self.id = UUID()
        self.name = name
        self.prompt = prompt
        self.bpm = bpm
        self.key = nil
        self.instrument = instrument
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.createdAt = Date()
        // Generate fake waveform data
        self.waveformData = (0..<50).map { i in
            sin(Float(i) * 0.2) * 0.5 + 0.5 + Float.random(in: 0...0.3)
        }
    }
}

struct Track: Identifiable, Codable {
    let id: UUID
    let title: String
    let artist: String
    let avatar: String
    let genre: String
    let duration: String
    var likes: Int
    let collaborators: Int
    var isOpen: Bool
    let type: TrackType
    let description: String?
    
    init(title: String, artist: String, avatar: String, genre: String, duration: String, likes: Int, collaborators: Int, isOpen: Bool, type: TrackType, description: String?) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.avatar = avatar
        self.genre = genre
        self.duration = duration
        self.likes = likes
        self.collaborators = collaborators
        self.isOpen = isOpen
        self.type = type
        self.description = description
    }
    
    enum TrackType: String, CaseIterable, Codable {
        case track = "track"
        case stem = "stem"
        case collaboration = "collaboration"
        
        var icon: String {
            switch self {
            case .track: return "music.note"
            case .stem: return "bolt.fill"
            case .collaboration: return "person.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .track: return .blue
            case .stem: return .purple
            case .collaboration: return Color.primaryBlue
            }
        }
    }
}

class AudioManager: ObservableObject {
    @Published var layers: [Layer] = []
    @Published var isGenerating = false
    @Published var currentPrompt = "a dreamy synth melody inspired by Tame Impala, 120 BPM"
    @Published var showSuggestion = true
    
    private var timer: Timer?
    
    let suggestedPrompts = [
        "a dreamy synth melody inspired by Tame Impala, 120 BPM",
        "a punchy lo-fi drum beat",
        "smooth jazz bass line in F major",
        "ambient pad sounds with reverb",
        "uplifting acoustic guitar strumming"
    ]
    
    func createLayer() {
        guard !currentPrompt.isEmpty else { return }
        
        isGenerating = true
        showSuggestion = false
        
        // Simulate AI generation delay
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...5)) {
            let layerName = self.currentPrompt.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "New Layer"
            let newLayer = Layer(name: layerName, prompt: self.currentPrompt)
            
            self.layers.append(newLayer)
            self.isGenerating = false
            
            // Auto-play the new layer
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.toggleLayerPlayback(layerId: newLayer.id)
            }
            
            // Show next suggestion
            if self.layers.count == 1 {
                self.currentPrompt = self.suggestedPrompts[1]
                self.showSuggestion = true
            } else {
                self.currentPrompt = ""
            }
        }
    }
    
    func toggleLayerPlayback(layerId: UUID) {
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].isPlaying.toggle()
            
            if layers[index].isPlaying {
                startTimer(for: layerId)
            } else {
                stopTimer()
            }
        }
    }
    
    private func startTimer(for layerId: UUID) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let index = self.layers.firstIndex(where: { $0.id == layerId && $0.isPlaying }) {
                self.layers[index].currentTime += 0.1
                if self.layers[index].currentTime >= self.layers[index].duration {
                    self.layers[index].currentTime = 0
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
