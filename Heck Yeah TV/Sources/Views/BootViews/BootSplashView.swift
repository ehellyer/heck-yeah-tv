//
//  BootSplashView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/19/25.
//

import SwiftUI
import AVFoundation

// MARK: - Boot Splash

struct BootSplashView: View {
    
    public var title: String
    public var subtitle: String
    public var autoPlaySound: Bool
    public var soundName: String
    public var soundExt: String
    
    @State private var angle: Double = 0
    @State private var didPlay = false
    
    init(
        title: String = "Heck\u{00A0}Yeah\u{00A0}TV!",
        subtitle: String = "Booting…",
        autoPlaySound: Bool = true,
        soundName: String = "boot-chime",
        soundExt: String = "wav"
    ) {
        self.title = title
        self.subtitle = subtitle
        self.autoPlaySound = autoPlaySound
        self.soundName = soundName
        self.soundExt = soundExt
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            // Animated gradient background
            AngularGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.9),
                    Color.indigo.opacity(0.9),
                    Color.blue.opacity(0.9),
                    Color.purple.opacity(0.9)
                ]),
                center: .center
            )
        
            .rotationEffect(.degrees(angle))
            .onAppear {
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: false)) {
                    angle = 360
                }
            }
            
            // Pulsing rings
            PulsingRings()
                .blendMode(.lighten)
                .allowsHitTesting(false)
            
            // Logo + shimmer
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, .white],
                                                    startPoint: .top,
                                                    endPoint: .bottom))
//                    .shadow(radius: 10, y: 4)
                
                // Subline + activity
                HStack(spacing: 8) {
                    Text(subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .transition(.opacity)
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
                .padding(.top, 1)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(title). \(subtitle)")
            }
            .padding(1)
        }
        .onAppear {
            playBootChimeIfNeeded()
        }
        .focusEffectDisabled(true)
    }
    
    private func playBootChimeIfNeeded() {
        guard autoPlaySound, !didPlay else { return }
        didPlay = true
        BootSoundPlayer.shared.play(resource: soundName, ext: soundExt)
    }
}

// MARK: - Simple audio helper

final class BootSoundPlayer: NSObject, @unchecked Sendable {
    static let shared = BootSoundPlayer()
    private var player: AVAudioPlayer?
    
    func play(resource: String, ext: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            return // silently ignore if missing
        }
        
#if os(iOS) || os(tvOS) || os(visionOS)
        // Configure an unobtrusive session that respects user audio
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
#endif
        
        do {
            let audio = try AVAudioPlayer(contentsOf: url)
            audio.volume = 0.9
            audio.prepareToPlay()
            audio.play()
            self.player = audio // retain
        } catch {
            // Ignore: boot chime is optional
        }
    }
}

// MARK: - Usage: gate your app while booting

/// Example container that shows the splash until `isReady` is true.
/// Use this to wrap your root content while async startup runs.
public struct BootGate<Content: View>: View {
    @Binding var isReady: Bool
    let content: () -> Content
    
    public init(isReady: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._isReady = isReady
        self.content = content
    }
    
    public var body: some View {
        ZStack {
            content().opacity(isReady ? 1 : 0)
            if !isReady {
                BootSplashView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: isReady)
    }
}

// MARK: - Previews

#Preview("Splash – iOS") {
    BootSplashView()
}

#if os(tvOS)
#Preview("Splash – tvOS") {
    BootSplashView()
}
#endif

#Preview("Gate (simulated)") {
    struct Demo: View {
        @State private var ready = false
        var body: some View {
            BootGate(isReady: $ready) {
                Text("Main App")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.9))
                    .foregroundStyle(.white)
            }
            .task {
                // Simulate your tuner/stream startup here
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                ready = true
            }
        }
    }
    return Demo()
}
