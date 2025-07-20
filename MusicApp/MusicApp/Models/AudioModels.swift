import SwiftUI
import Combine
import AVFoundation

struct Layer: Identifiable, Codable {
    let id: UUID
    let name: String
    let prompt: String
    var isPlaying: Bool = false
    let duration: TimeInterval
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
        case all = "All"
        case percussion = "Percussion"
        case bass = "Bass"
        case melody = "Melody"
        case chords = "Chords"
        
        var icon: String {
            switch self {
            case .all: return "music.note.list"
            case .percussion: return "metronome"
            case .bass: return "waveform"
            case .melody: return "music.note"
            case .chords: return "music.quarternote.3"
            }
        }
    }
    
    init(id: UUID? = nil, name: String, prompt: String, bpm: Int = 120, instrument: InstrumentType = .all, creatorId: UUID? = nil, creatorName: String? = nil, audioURL: URL? = nil) {
        self.id = id ?? UUID()
        self.name = name
        self.prompt = prompt
        self.bpm = bpm
        self.key = nil
        self.instrument = instrument
        self.creatorId = creatorId
        self.creatorName = creatorName
        self.createdAt = Date()
        self.audioURL = audioURL
        self.duration = 30.0
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

@MainActor
class AudioManager: NSObject, ObservableObject {
    @Published var layers: [Layer] = []
    @Published var isGenerating = false
    @Published var currentPrompt = "a dreamy synth melody inspired by Tame Impala, 120 BPM"
    @Published var showSuggestion = true
    @Published var selectedInstrument: Layer.InstrumentType = .all
    @Published var bpm: String = "120"
    
    private var timer: Timer?
    private var players: [UUID: AVPlayer] = [:]
    private var playerObservers: [UUID: Any] = [:]
    private var pendingLayerId: UUID?
    
    let suggestedPrompts = [
        "a dreamy synth melody inspired by Tame Impala, 120 BPM",
        "a punchy lo-fi drum beat",
        "smooth jazz bass line in F major",
        "ambient pad sounds with reverb",
        "uplifting acoustic guitar strumming"
    ]
    
    override init() {
        super.init()
        setupAudioSession()
        createAudioDirectory()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("[AudioPlayer] Audio session configured for playback")
        } catch {
            print("[AudioPlayer] Failed to setup audio session: \(error)")
        }
    }
    
    private func createAudioDirectory() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let audioPath = documentsPath.appendingPathComponent("AudioFiles")
        
        if !FileManager.default.fileExists(atPath: audioPath.path) {
            do {
                try FileManager.default.createDirectory(at: audioPath, withIntermediateDirectories: true)
                print("[AudioPlayer] Created audio directory at: \(audioPath)")
            } catch {
                print("[AudioPlayer] Failed to create audio directory: \(error)")
            }
        }
    }
    
    private func downloadAndSaveAudio(from url: URL, taskId: String) async -> URL? {
        print("[AudioDownload] 🔄 Starting download from: \(url.absoluteString)")
        
        do {
            print("[AudioDownload] 📡 Requesting audio data...")
            let (data, response) = try await URLSession.shared.data(from: url)
            
            print("[AudioDownload] 📊 Response received: \(response)")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("[AudioDownload] ❌ Invalid response type")
                return nil
            }
            
            print("[AudioDownload] 🔍 HTTP Status Code: \(httpResponse.statusCode)")
            print("[AudioDownload] 📋 Response Headers: \(httpResponse.allHeaderFields)")
            
            guard httpResponse.statusCode == 200 else {
                print("[AudioDownload] ❌ Failed to download audio - Status: \(httpResponse.statusCode)")
                return nil
            }
            
            print("[AudioDownload] 📦 Data received: \(data.count) bytes")
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let audioPath = documentsPath.appendingPathComponent("AudioFiles")
            let fileName = "\(taskId).wav"
            let localURL = audioPath.appendingPathComponent(fileName)
            
            print("[AudioDownload] 📁 Saving to: \(localURL.path)")
            
            // Ensure directory exists
            try FileManager.default.createDirectory(at: audioPath, withIntermediateDirectories: true, attributes: nil)
            
            try data.write(to: localURL)
            
            // Verify file was written
            if FileManager.default.fileExists(atPath: localURL.path) {
                let fileSize = try FileManager.default.attributesOfItem(atPath: localURL.path)[FileAttributeKey.size] as? NSNumber
                print("[AudioDownload] ✅ Audio file saved successfully")
                print("[AudioDownload] 📄 Local file: \(localURL.path)")
                print("[AudioDownload] 📊 File size: \(fileSize?.intValue ?? 0) bytes")
                return localURL
            } else {
                print("[AudioDownload] ❌ File was not saved properly")
                return nil
            }
        } catch {
            print("[AudioDownload] ❌ Error downloading/saving audio: \(error)")
            print("[AudioDownload] 🔍 Error details: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Retrieves the Beatoven API key from Secrets.plist
    /// Expected keys in order of preference:
    /// 1. BEATOVEN_API_KEY - Specific key for Beatoven API
    /// 2. API_KEY - Generic key (for backward compatibility)
    private func getBeatovenAPIKey() -> String? {
        // Debug: List all plist files in bundle
        if let resourcePath = Bundle.main.resourcePath {
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                let plistFiles = items.filter { $0.hasSuffix(".plist") }
                print("[Beatoven] Found plist files in bundle: \(plistFiles)")
            } catch {
                print("[Beatoven] Error listing bundle contents: \(error)")
            }
        }
        
        // Load Secrets.plist
        guard let path = Bundle.main.path(forResource: "Secrets", ofType: "plist") else {
            print("[Beatoven] ❌ ERROR: Secrets.plist file not found in bundle")
            print("[Beatoven] Please ensure Secrets.plist is added to your project and included in the target")
            return nil
        }
        
        print("[Beatoven] Loading Secrets.plist from: \(path)")
        
        guard let dict = NSDictionary(contentsOfFile: path) else {
            print("[Beatoven] ❌ ERROR: Failed to load dictionary from Secrets.plist")
            return nil
        }
        
        // Debug: Print all available keys
        print("[Beatoven] Available keys in Secrets.plist: \(dict.allKeys)")
        
        // Try to get Beatoven-specific key first
        if let beatovenKey = dict["BEATOVEN_API_KEY"] as? String {
            print("[Beatoven] ✅ Found BEATOVEN_API_KEY")
            // Validate it's not a Supabase key
            if beatovenKey.hasPrefix("sb_") {
                print("[Beatoven] ⚠️ WARNING: BEATOVEN_API_KEY appears to be a Supabase key (starts with 'sb_')")
                print("[Beatoven] Please update BEATOVEN_API_KEY in Secrets.plist with your actual Beatoven API key")
                return nil
            }
            return beatovenKey
        }
        
        // Fall back to generic API_KEY for backward compatibility
        if let apiKey = dict["API_KEY"] as? String {
            print("[Beatoven] ⚠️ Found API_KEY (using as fallback - consider using BEATOVEN_API_KEY instead)")
            // Validate it's not a Supabase key
            if apiKey.hasPrefix("sb_") {
                print("[Beatoven] ❌ ERROR: API_KEY contains a Supabase key (starts with 'sb_')")
                print("[Beatoven] Please update API_KEY in Secrets.plist with your actual Beatoven API key")
                print("[Beatoven] Or add a new entry BEATOVEN_API_KEY with your Beatoven API key")
                return nil
            }
            return apiKey
        }
        
        // No valid key found
        print("[Beatoven] ❌ ERROR: No valid Beatoven API key found in Secrets.plist")
        print("[Beatoven] Please add one of the following keys to your Secrets.plist:")
        print("[Beatoven]   - BEATOVEN_API_KEY (recommended)")
        print("[Beatoven]   - API_KEY")
        print("[Beatoven] Make sure the value is your actual Beatoven API key, not a Supabase key")
        
        return nil
    }
    
    
    func createLayer() {
        guard !currentPrompt.isEmpty else { return }
        isGenerating = true
        showSuggestion = false
        Task {
            do {
                guard let apiKey = getBeatovenAPIKey() else {
                    print("[Beatoven] ❌ Failed to retrieve Beatoven API key")
                    await MainActor.run {
                        self.isGenerating = false
                    }
                    return
                }
                
                print("[Beatoven] API Key retrieved: \(String(apiKey.prefix(10)))...")
                print("[Beatoven] API Key length: \(apiKey.count)")
                // Compose request
                let composeURL = URL(string: "https://public-api.beatoven.ai/api/v1/tracks/compose")!
                var request = URLRequest(url: composeURL)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                // Build enhanced prompt with instrument and BPM
                var enhancedPrompt = self.currentPrompt
                if !enhancedPrompt.lowercased().contains("bpm") {
                    enhancedPrompt += ", \(self.bpm) BPM"
                }
                
                let body: [String: Any] = [
                    "prompt": ["text": enhancedPrompt],
                    "format": "wav",
                    "looping": false
                ]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                print("[Beatoven] Sending compose request...")
                print("[Beatoven] Request headers: \(request.allHTTPHeaderFields ?? [:])")
                print("[Beatoven] Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "nil")")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("[Beatoven] Response status code: \(httpResponse.statusCode)")
                    print("[Beatoven] Response headers: \(httpResponse.allHeaderFields)")
                    
                    if httpResponse.statusCode != 200 {
                        print("[Beatoven] Response body: \(String(data: data, encoding: .utf8) ?? "nil")")
                    }
                }
                
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
                        print("[DEBUG] Status is composed, checking for audio URL...")
                        
                        // The track_url and stems_url are nested inside the meta object
                        if let meta = statusResult["meta"] as? [String: Any] {
                            var urlString: String?
                            
                            // Determine which URL to use based on selected instrument
                            switch self.selectedInstrument {
                            case .all:
                                // Use the full track URL for "All" instrument type
                                urlString = meta["track_url"] as? String
                                print("[DEBUG] Selected 'All' - using track_url")
                                
                            case .bass, .chords, .melody, .percussion:
                                // Use the corresponding stem URL
                                if let stemsUrl = meta["stems_url"] as? [String: Any] {
                                    let stemKey = self.selectedInstrument.rawValue.lowercased()
                                    urlString = stemsUrl[stemKey] as? String
                                    print("[DEBUG] Selected '\(self.selectedInstrument.rawValue)' - using stems_url.\(stemKey)")
                                } else {
                                    print("[DEBUG] No stems_url found in meta object")
                                }
                            }
                            
                            if let urlString = urlString, let url = URL(string: urlString) {
                                print("[Beatoven] Audio URL: \(url)")
                                print("[AudioPlayer] Starting download process...")
                                print("[DEBUG] About to call downloadAndSaveAudio...")
                                
                                // Store the remote URL for Supabase
                                let remoteURLString = urlString
                                
                                // Download and save audio file locally
                                if let localURL = await self.downloadAndSaveAudio(from: url, taskId: taskId) {
                                    trackURL = localURL
                                    print("[AudioPlayer] ✅ Audio saved locally at: \(localURL)")
                                    print("[AudioPlayer] Will use local file for playback")
                                } else {
                                    // Fallback to remote URL if download fails
                                    trackURL = url
                                    print("[AudioPlayer] ❌ Download failed, using remote URL as fallback")
                                }
                                
                                // Save track to Supabase here while we have access to all data
                                let bpmValue = Int(self.bpm) ?? 120
                                let layerId = UUID()
                                
                                // Create and save track to Supabase
                                Task {
                                    do {
                                        let metadata: [String: Any] = [
                                            "instrument": self.selectedInstrument.rawValue,
                                            "bpm": bpmValue,
                                            "prompt": self.currentPrompt,
                                            "duration": 30.0,
                                            "task_id": taskId
                                        ]
                                        try await SupabaseManager.shared.saveTrack(
                                            layerId: layerId.uuidString,
                                            trackUrl: remoteURLString,
                                            collaborationId: nil,
                                            metadata: metadata
                                        )
                                        print("[Supabase] Track saved successfully with remote URL: \(remoteURLString)")
                                    } catch {
                                        print("[Supabase] Failed to save track to Supabase: \(error)")
                                    }
                                }
                                
                                // Store the layer ID for later use
                                await MainActor.run {
                                    self.pendingLayerId = layerId
                                }
                            } else {
                                print("[DEBUG] Failed to get valid URL for instrument: \(self.selectedInstrument.rawValue)")
                                print("[DEBUG] Available keys in statusResult: \(statusResult.keys)")
                                if let meta = statusResult["meta"] as? [String: Any] {
                                    print("[DEBUG] Available keys in meta: \(meta.keys)")
                                    if let stemsUrl = meta["stems_url"] as? [String: Any] {
                                        print("[DEBUG] Available stems: \(stemsUrl.keys)")
                                    }
                                }
                            }
                        } else {
                            print("[DEBUG] No meta object found in statusResult")
                            print("[DEBUG] Available keys in statusResult: \(statusResult.keys)")
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
                
                // Use the pending layer ID if we saved to Supabase, otherwise create new
                let layerId = self.pendingLayerId ?? UUID()
                let newLayer = Layer(
                    id: layerId,
                    name: layerName, 
                    prompt: self.currentPrompt, 
                    bpm: bpmValue,
                    instrument: self.selectedInstrument,
                    audioURL: trackURL
                )
                
                // Clear pending layer ID
                self.pendingLayerId = nil
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
            layers[index].isPlaying.toggle()
            if layers[index].isPlaying {
                if let url = layers[index].audioURL {
                    resumeAudio(for: layerId, url: url)
                } else {
                    startTimer(for: layerId)
                }
            } else {
                if let _ = layers[index].audioURL {
                    pausePlayer(for: layerId)
                } else {
                    stopTimer()
                }
            }
        }
    }
    
    func playAllLayers() {
        for layer in layers {
            if !layer.isPlaying {
                toggleLayerPlayback(layerId: layer.id)
            }
        }
    }
    
    func stopAllLayers() {
        for layer in layers {
            if layer.isPlaying {
                toggleLayerPlayback(layerId: layer.id)
            }
        }
    }
    
    func deleteLayer(layerId: UUID) {
        // Stop the layer if it's playing
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            if layers[index].isPlaying {
                stopPlayer(for: layerId)
            }
        }
        
        // Remove from layers array
        layers.removeAll { $0.id == layerId }
        
        // Clean up player and observers
        players.removeValue(forKey: layerId)
        playerObservers.removeValue(forKey: layerId)
        
        print("[AudioPlayer] Deleted layer: \(layerId)")
    }
    
    private func startTimer(for layerId: UUID) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if let index = self.layers.firstIndex(where: { $0.id == layerId && $0.isPlaying }) {
                    self.layers[index].currentTime += 0.1
                    if self.layers[index].currentTime >= self.layers[index].duration {
                        self.layers[index].currentTime = 0
                    }
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func resumeAudio(for layerId: UUID, url: URL) {
        // If player already exists, just resume
        if let player = players[layerId] {
            print("[AudioPlayer] Resuming existing player for layer: \(layerId)")
            player.play()
            return
        }
        
        // If no player exists, create new one
        playAudio(for: layerId, url: url)
    }
    
    private func pausePlayer(for layerId: UUID) {
        if let player = players[layerId] {
            player.pause()
            print("[AudioPlayer] Paused player for layer: \(layerId)")
        }
    }
    
    private func playAudio(for layerId: UUID, url: URL) {
        stopPlayer(for: layerId)
        
        print("[AudioPlayer] Attempting to play audio from URL: \(url.absoluteString)")
        
        // Check if it's a local file URL
        if url.isFileURL {
            print("[AudioPlayer] Playing local file")
        } else {
            print("[AudioPlayer] Playing remote URL")
        }
        
        // Configure audio session before playing
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
            print("[AudioPlayer] Audio session activated successfully")
        } catch {
            print("[AudioPlayer] Failed to activate audio session: \(error)")
        }
        
        // Create player item to check status
        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        
        // Seek to current time if resuming
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            let currentTime = layers[index].currentTime
            if currentTime > 0 {
                let seekTime = CMTime(seconds: currentTime, preferredTimescale: 600)
                player.seek(to: seekTime)
                print("[AudioPlayer] Seeking to: \(currentTime) seconds")
            }
        }
        
        // Observe player item status
        playerItem.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        
        // Log player status
        print("[AudioPlayer] Creating player for URL: \(url)")
        print("[AudioPlayer] Player item status: \(playerItem.status.rawValue)")
        
        players[layerId] = player
        // Observe time
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        let observer = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
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
        }
        playerObservers[layerId] = observer
        
        // Debug logs
        print("[AudioPlayer] Playing audio for layer: \(layerId) from URL: \(url)")
        
        // Add notification observer for playback
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            print("[AudioPlayer] Playback ended for layer: \(layerId)")
            Task { @MainActor in
                self?.stopPlayer(for: layerId)
            }
        }
        
        // Wait for player item to be ready
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: playerItem,
            queue: .main
        ) { _ in
            print("[AudioPlayer] Player item access log entry")
        }
        
        // Observe when player is ready
        player.addObserver(self, forKeyPath: "status", options: [.new], context: nil)
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)
        
        // Set volume before playing
        player.volume = 1.0
        
        // Play when ready
        if playerItem.status == .readyToPlay {
            player.play()
            print("[AudioPlayer] Playing immediately - item ready")
        } else {
            // Wait for readyToPlay status
            print("[AudioPlayer] Waiting for player item to be ready...")
        }
    }

    private func stopPlayer(for layerId: UUID) {
        // Remove observer if exists
        if let observer = playerObservers[layerId], let player = players[layerId] {
            player.removeTimeObserver(observer)
            print("[AudioPlayer] Removed time observer for layer: \(layerId)")
        }
        
        if let player = players[layerId] {
            player.pause()
            print("[AudioPlayer] Paused player for layer: \(layerId)")
        }
        
        players[layerId] = nil
        playerObservers[layerId] = nil
        if let index = layers.firstIndex(where: { $0.id == layerId }) {
            layers[index].isPlaying = false
        }
    }
    
    // KVO observer for player item status
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if let playerItem = object as? AVPlayerItem {
                switch playerItem.status {
                case .readyToPlay:
                    print("[AudioPlayer] Player item ready to play")
                    print("[AudioPlayer] Duration: \(playerItem.duration.seconds) seconds")
                    
                    // Find the player for this item and play it
                    for (layerId, player) in players {
                        if player.currentItem == playerItem {
                            DispatchQueue.main.async {
                                player.play()
                                print("[AudioPlayer] Started playback for layer: \(layerId)")
                                print("[AudioPlayer] Player rate: \(player.rate)")
                                print("[AudioPlayer] Player volume: \(player.volume)")
                            }
                            break
                        }
                    }
                case .failed:
                    print("[AudioPlayer] Player item failed: \(playerItem.error?.localizedDescription ?? "unknown error")")
                    if let error = playerItem.error as NSError? {
                        print("[AudioPlayer] Error domain: \(error.domain)")
                        print("[AudioPlayer] Error code: \(error.code)")
                        print("[AudioPlayer] Error info: \(error.userInfo)")
                    }
                case .unknown:
                    print("[AudioPlayer] Player item status unknown")
                @unknown default:
                    print("[AudioPlayer] Player item unknown status")
                }
            } else if let player = object as? AVPlayer {
                if keyPath == "status" {
                    print("[AudioPlayer] Player status: \(player.status.rawValue)")
                } else if keyPath == "timeControlStatus" {
                    switch player.timeControlStatus {
                    case .paused:
                        print("[AudioPlayer] Player paused")
                    case .playing:
                        print("[AudioPlayer] Player playing")
                    case .waitingToPlayAtSpecifiedRate:
                        print("[AudioPlayer] Player waiting to play")
                        if let reason = player.reasonForWaitingToPlay {
                            print("[AudioPlayer] Waiting reason: \(reason.rawValue)")
                        }
                    @unknown default:
                        print("[AudioPlayer] Unknown time control status")
                    }
                }
            }
        }
    }
}
