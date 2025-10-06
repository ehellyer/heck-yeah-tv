//
//  BootSplashView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
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
    
    @State private var didPlay = false
    
    init(title: String = "Heck\u{00A0}Yeah\u{00A0}TV",
         subtitle: String = "Discovering channels...",
         autoPlaySound: Bool = true,
         soundName: String = "soft-startup-sound",
         soundExt: String = "mp3") {
        self.title = title
        self.subtitle = subtitle
        self.autoPlaySound = autoPlaySound
        self.soundName = soundName
        self.soundExt = soundExt
    }
    
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.mainAppGreen, .black, .mainAppGreen],
                           startPoint: UnitPoint(x: 0, y: 0),
                           endPoint: UnitPoint(x: 0.25, y: 1.7))
                .ignoresSafeArea()
            
            PulsingRings()
                .blendMode(.lighten)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 90,
                                  weight: .heavy,
                                  design: .rounded))
                    .foregroundStyle(Color.mainAppGreen)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 10) {
                    Text(subtitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.mainAppGreen)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(title). \(subtitle)")
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 40)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 50, style: .continuous))
            .shadow(radius: 66)
        }
        
        .allowsHitTesting(false)
        
        .onAppear {
            playBootChimeIfNeeded()
        }
    }
    
    private func playBootChimeIfNeeded() {
        guard autoPlaySound, !didPlay else { return }
        didPlay = true
        BootSoundPlayer.shared.play(resource: soundName, ext: soundExt)
    }
}

//MARK: - Audio helper

final class BootSoundPlayer: NSObject, @unchecked Sendable {
    static let shared = BootSoundPlayer()
    private var player: AVAudioPlayer?
    
    func play(resource: String, ext: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            return
        }
#if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.duckOthers])
        try? session.setActive(true, options: [])
#endif
        do {
            let audio = try AVAudioPlayer(contentsOf: url)
            audio.volume = 1.0
            audio.prepareToPlay()
            audio.play()
            self.player = audio
        } catch {
            // Ignore: boot chime is optional
        }
    }
}

// MARK: - Previews

#Preview("Splash") {
    BootSplashView()
}

#Preview("Gated splash (simulated)") {
    struct Demo: View {
        @State private var ready = false
        var body: some View {
            BootGateView(isReady: $ready) {
                Text("Main App")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.9))
                    .foregroundStyle(.white)
            }
            .task {
                // Simulate tuner/stream startup here
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                ready = true
            }
        }
    }
    return Demo()
}
