import SwiftUI

struct LayerControlView: View {
    @Binding var layer: Layer
    @ObservedObject var audioManager: AudioManager
    @State private var showOptions = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Layer Card
            HStack(spacing: 12) {
                // Play/Pause Button
                Button(action: {
                    audioManager.toggleLayerPlayback(layerId: layer.id)
                }) {
                    Image(systemName: layer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(LinearGradient.primaryGradient)
                        .clipShape(Circle())
                }
                
                // Layer Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: layer.instrument.icon)
                            .font(.caption)
                            .foregroundColor(Color.primaryPurple)
                        
                        Text(layer.name)
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        if layer.isPublic {
                            Image(systemName: "globe")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Text(layer.prompt)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                        .lineLimit(1)
                    
                    // Waveform
                    LayerWaveformView(data: layer.waveformData, progress: layer.currentTime / layer.duration)
                        .frame(height: 30)
                }
                
                Spacer()
                
                // Volume & Controls
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        // Mute
                        Button(action: {
                            layer.isMuted.toggle()
                        }) {
                            Image(systemName: layer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.caption)
                                .foregroundColor(layer.isMuted ? .red : .secondaryText)
                                .frame(width: 28, height: 28)
                                .background(Color.cardBackground)
                                .clipShape(Circle())
                        }
                        
                        // Solo
                        Button(action: {
                            layer.isSolo.toggle()
                        }) {
                            Text("S")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(layer.isSolo ? .yellow : .secondaryText)
                                .frame(width: 28, height: 28)
                                .background(Color.cardBackground)
                                .clipShape(Circle())
                        }
                        
                        // Options
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                showOptions.toggle()
                            }
                        }) {
                            Image(systemName: "ellipsis")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                                .frame(width: 28, height: 28)
                                .background(Color.cardBackground)
                                .clipShape(Circle())
                        }
                    }
                    
                    // Volume Slider
                    VolumeSlider(volume: $layer.volume)
                        .frame(width: 100)
                }
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(layer.currentTime > 0 ? Color.primaryPurple.opacity(0.5) : Color.borderColor, lineWidth: 1)
            )
            
            // Options Menu
            if showOptions {
                LayerOptionsMenu(
                    layer: $layer,
                    onDelete: {
                        // Handle delete
                    },
                    onDuplicate: {
                        // Handle duplicate
                    },
                    onExport: {
                        // Handle export
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
    }
}

struct LayerWaveformView: View {
    let data: [Float]
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<data.count, id: \.self) { index in
                    // Ensure progress is valid
                    let safeProgress = progress.isNaN || progress.isInfinite ? 0 : max(0, min(1, progress))
                    let isActive = index < Int(Double(data.count) * safeProgress)
                    let barWidth = max(1, geometry.size.width / CGFloat(data.count) - 2)
                    let barHeight = geometry.size.height * CGFloat(data[index])
                    
                    Rectangle()
                        .fill(isActive ? Color.purple : Color.gray.opacity(0.3))
                        .frame(width: barWidth, height: barHeight)
                }
            }
        }
    }
}

struct VolumeSlider: View {
    @Binding var volume: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(Color.secondaryText.opacity(0.2))
                    .frame(height: 4)
                
                // Fill
                Capsule()
                    .fill(LinearGradient.primaryGradient)
                    .frame(width: geometry.size.width * CGFloat(volume), height: 4)
                
                // Knob
                Circle()
                    .fill(Color.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                    .offset(x: geometry.size.width * CGFloat(volume) - 6)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newVolume = Float(value.location.x / geometry.size.width)
                                volume = max(0, min(1, newVolume))
                            }
                    )
            }
        }
        .frame(height: 12)
    }
}

struct LayerOptionsMenu: View {
    @Binding var layer: Layer
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onExport: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            OptionButton(icon: "square.on.square", title: "Duplicate", action: onDuplicate)
            Divider()
            OptionButton(icon: "square.and.arrow.up", title: "Export", action: onExport)
            Divider()
            OptionButton(icon: layer.isPublic ? "lock" : "globe", title: layer.isPublic ? "Make Private" : "Make Public", action: {
                layer.isPublic.toggle()
            })
            Divider()
            OptionButton(icon: "trash", title: "Delete", color: .red, action: onDelete)
        }
        .background(Color.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 4)
    }
}

struct OptionButton: View {
    let icon: String
    let title: String
    var color: Color = .primaryText
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .frame(width: 20)
                Text(title)
                    .font(.caption)
                Spacer()
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }
}
