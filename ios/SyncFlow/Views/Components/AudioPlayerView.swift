import SwiftUI

struct AudioPlayerView: View {
    let layer: Layer?
    let isLoading: Bool
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                LoadingPlayerView()
            } else if let layer = layer {
                ActivePlayerView(layer: layer)
            }
        }
        .cardStyle()
    }
}

struct LoadingPlayerView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primaryPurple.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.primaryPurple)
                    )
                    .scaleEffect(1.0 + sin(animationOffset) * 0.1)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.borderColor)
                        .frame(height: 16)
                        .shimmer()
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.borderColor.opacity(0.5))
                        .frame(height: 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(width: 120)
                        .shimmer()
                }
                
                Spacer()
            }
            
            // Loading Waveform
            HStack(spacing: 2) {
                ForEach(0..<50, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.borderColor)
                        .frame(height: CGFloat.random(in: 10...40))
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever()
                            .delay(Double(i) * 0.02),
                            value: animationOffset
                        )
                }
            }
            .frame(height: 64)
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationOffset = .pi * 2
            }
        }
    }
}

struct ActivePlayerView: View {
    let layer: Layer
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    audioManager.toggleLayerPlayback(layerId: layer.id)
                }) {
                    Image(systemName: layer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .scaleEffect(layer.isPlaying ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: layer.isPlaying)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(layer.name)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Text("\(Int(layer.currentTime))s / \(Int(layer.duration))s")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "speaker.wave.2")
                    .foregroundColor(.secondaryText)
            }
            
            // Waveform Visualization
            WaveformView(
                waveformData: layer.waveformData,
                currentTime: layer.currentTime,
                duration: layer.duration,
                isPlaying: layer.isPlaying
            )
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.borderColor)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geometry.size.width * (layer.currentTime / layer.duration), height: 4)
                        .animation(.linear(duration: 0.1), value: layer.currentTime)
                }
            }
            .frame(height: 4)
        }
    }
}

struct WaveformView: View {
    let waveformData: [Float]
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(Array(waveformData.enumerated()), id: \.offset) { index, amplitude in
                let progress = currentTime / duration
                let barProgress = Double(index) / Double(waveformData.count)
                let isActive = progress > barProgress
                
                RoundedRectangle(cornerRadius: 1)
                    .fill(isActive ? LinearGradient.primaryGradient : Color.borderColor.gradient)
                    .frame(height: CGFloat(amplitude * 60))
                    .opacity(isActive ? 1.0 : 0.6)
                    .scaleEffect(isPlaying && isActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isActive)
            }
        }
        .frame(height: 64)
    }
}

extension View {
    func shimmer() -> some View {
        self.overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: -200)
                .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: UUID())
        )
        .clipped()
    }
}

#Preview {
    VStack(spacing: 16) {
        AudioPlayerView(layer: nil, isLoading: true)
        AudioPlayerView(
            layer: Layer(name: "Dreamy Synth", prompt: "a dreamy synth melody"),
            isLoading: false
        )
    }
    .padding()
    .background(Color.darkBackground)
    .environmentObject(AudioManager())
}
