import SwiftUI
import Combine
import AVFoundation

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
    var audioURL: URL? // <-- Added for Beatoven audio
    
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
    
    init(name: String, prompt: String, bpm: Int = 120, instrument: InstrumentType = .other, creatorId: UUID? = nil, creatorName: String? = nil, audioURL: URL? = nil) {
        self.id = UUID()
        self.name = name
        self.prompt = prompt
        self.bpm = bpm
        self.key = nil
        self.instrument = instrument
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.createdAt = Date()
        self.audioURL = audioURL
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
    @Published var selectedInstrument: Layer.InstrumentType = .other
    @Published var bpm: String = "120"
    
    private var timer: Timer?
    private var players: [UUID: AVPlayer] = [:]
    private var playerObservers: [UUID: Any] = [:]
    
    let suggestedPrompts = [
        "a dreamy synth melody inspired by Tame Impala, 120 BPM",
        "a punchy lo-fi drum beat",
        "smooth jazz bass line in F major",
        "ambient pad sounds with reverb",
        "uplifting acoustic guitar strumming"
    ]
    
    func getAPIKey() -> String? {
       guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
             let dict = NSDictionary(contentsOfFile: path),
             let key = dict["API_KEY"] as? String else {
           print("API Key not found")
           return nil
       }
       return key
    }
    
    func createLayer() {
        guard !currentPrompt.isEmpty else { return }
        isGenerating = true
        showSuggestion = false
        Task {
            do {
                guard let apiKey = getAPIKey() else {
                    print("API Key not found")
                    isGenerating = false
                    return
                }
                // Compose request
                let composeURL = URL(string: "https://public-api.beatoven.ai/api/v1/tracks/compose")!
                var request = URLRequest(url: composeURL)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                // Build enhanced prompt with instrument and BPM
                var enhancedPrompt = self.currentPrompt
                if self.selectedInstrument != .other {
                    enhancedPrompt = "\(self.selectedInstrument.rawValue.lowercased()) - \(enhancedPrompt)"
                }
                if !enhancedPrompt.lowercased().contains("bpm") {
                    enhancedPrompt += ", \(self.bpm) BPM"
                }
                
                let body: [String: Any] = [
                    "prompt": ["text": enhancedPrompt],
                    "format": "wav",
                    "looping": false
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    print("Compose API failed: \(response)")
                    isGenerating = false
                    return
                }
                guard let composeResult = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let taskId = composeResult["task_id"] as? String else {
                    print("Failed to parse compose response")
                    print("[Beatoven] Compose response: \(String(data: data, encoding: .utf8) ?? "<nil>")")
                    isGenerating = false
                    return
                }
                // Poll status
                let statusBaseURL = "https://public-api.beatoven.ai/api/v1/tasks/\(taskId)"
                var trackURL: URL? = nil
                let startTime = Date()
                while true {
                    try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    var statusRequest = URLRequest(url: URL(string: statusBaseURL)!)
                    statusRequest.httpMethod = "GET"
                    statusRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    let (statusData, statusResponse) = try await URLSession.shared.data(for: statusRequest)
                    guard let statusHTTP = statusResponse as? HTTPURLResponse, statusHTTP.statusCode == 200 else {
                        print("Status API failed: \(statusResponse)")
                        continue
                    }
                    guard let statusResult = try? JSONSerialization.jsonObject(with: statusData) as? [String: Any],
                          let status = statusResult["status"] as? String else {
                        print("Failed to parse status response")
                        continue
                    }
                    print("[Beatoven] Poll status: \(status)")
                    print("[Beatoven] Full statusResult: \(statusResult)")
                    if status == "composed" {
                        if let urlString = statusResult["track_url"] as? String, let url = URL(string: urlString) {
                            trackURL = url
                            print("[Beatoven] Composed track URL: \(url)")
                        }
                        break
                    }
                    // Timeout after 2 minutes
                    if Date().timeIntervalSince(startTime) > 120 {
                        print("Polling timed out.")
                        isGenerating = false
                        return
                    }
                }
                // Add new layer
                let layerName = self.currentPrompt.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? "New Layer"
                let bpmValue = Int(self.bpm) ?? 120
                let newLayer = Layer(
                    name: layerName, 
                    prompt: self.currentPrompt, 
                    bpm: bpmValue,
                    instrument: self.selectedInstrument,
                    audioURL: trackURL
                )
                await MainActor.run {
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
            } catch {
                print("Error in createLayer: \(error)")
                await MainActor.run { self.isGenerating = false }
            }
        }
    }
    
    func toggleLayerPlayback(layerId: UUID) {
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            // Stop all other layers
            for i in layers.indices {
                if layers[i].isPlaying && layers[i].id != layerId {
                    layers[i].isPlaying = false
                    stopPlayer(for: layers[i].id)
                }
            }
            layers[index].isPlaying.toggle()
            if layers[index].isPlaying {
                if let url = layers[index].audioURL {
                    playAudio(for: layerId, url: url)
                } else {
                    startTimer(for: layerId)
                }
            } else {
                if let _ = layers[index].audioURL {
                    stopPlayer(for: layerId)
                } else {
                    stopTimer()
                }
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
    
    private func playAudio(for layerId: UUID, url: URL) {
        stopPlayer(for: layerId)
        let player = AVPlayer(url: url)
        players[layerId] = player
        // Observe time
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        let observer = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            if let index = self.layers.firstIndex(where: { $0.id == layerId }) {
                let seconds = time.seconds
                self.layers[index].currentTime = seconds
                if seconds >= self.layers[index].duration {
                    self.layers[index].isPlaying = false
                    self.layers[index].currentTime = 0
                    self.stopPlayer(for: layerId)
                }
            }
        }
        playerObservers[layerId] = observer
        player.play()
    }

    private func stopPlayer(for layerId: UUID) {
        if let player = players[layerId] {
            player.pause()
            players[layerId] = nil
        }
        if let observer = playerObservers[layerId], let player = players[layerId] {
            player.removeTimeObserver(observer)
        }
        playerObservers[layerId] = nil
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].isPlaying = false
        }
    }
}
