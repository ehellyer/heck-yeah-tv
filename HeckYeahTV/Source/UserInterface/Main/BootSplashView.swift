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
    @State private var gradientStart = UnitPoint(x: 0, y: 0)
    @State private var gradientEnd = UnitPoint(x: 2, y: 2)
    
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
    
    // Adaptive font sizes based on platform
    private var titleFontSize: CGFloat {
#if os(tvOS)
        return 120
#elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 80 : 50
#elseif os(macOS)
        return 80
#elseif os(watchOS)
        return 30
#elseif os(visionOS)
        return 90
#else
        return 90
#endif
    }
    
    private var subtitleFontSize: CGFloat {
#if os(tvOS)
        return 50
#elseif os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad ? 40 : 24
#elseif os(macOS)
        return 32
#elseif os(watchOS)
        return 16
#elseif os(visionOS)
        return 40
#else
        return 40
#endif
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [.mainAppTheme, .black],
                               startPoint: gradientStart,
                               endPoint: gradientEnd)
                    .ignoresSafeArea()
                    .onAppear {
                        animateGradient(viewSize: geometry.size)
                    }
                
                DustyView()
                    .blendMode(.plusLighter)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Image(systemName: "tv")
                        .resizable()
                        .scaledToFill()
                        .foregroundStyle(Color.white.opacity(0.4))
#if os(tvOS)
                        .frame(width: 200, height: 200)
#else
                        .frame(width: 100, height: 100)
#endif
                    Text(title)
                        .font(.system(size: titleFontSize,
                                      weight: .heavy,
                                      design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 10) {
                        Text(subtitle)
                            .font(.system(size: subtitleFontSize,
                                          weight: .heavy,
                                          design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(title). \(subtitle)")
                }
            }
            
            .allowsHitTesting(false)
            
            .onAppear {
                playBootChimeIfNeeded()
            }
        }
    }
    
    private func animateGradient(viewSize: CGSize) {
        // Bounding circle diameter
        let diameter: Double = sqrt(pow(viewSize.width, 2) + pow(viewSize.height, 2))
        
        // Normalize to unit point scale (0-1)
        let radius: Double = diameter / max(viewSize.width, viewSize.height) / 2
        
        let angle: Double = 0
        let distance: Double = radius * 4
        let endAngle: Double = .pi
        
        // Calculate points on the circumference of the bounding circle
        let newStartX = (0.5 + cos(angle)) * (distance * 0.5)
        let newStartY = (0.5 + sin(angle)) *  (distance * 0.5)
        let newEndX = (0.5 + cos(endAngle)) * distance
        let newEndY = (0.5 + sin(endAngle)) * distance
        
        withAnimation(.easeOut(duration: 10.0).repeatForever(autoreverses: true)) {
            gradientStart = UnitPoint(x: newStartX, y: newStartY)
            gradientEnd = UnitPoint(x: newEndX, y: newEndY)
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
        guard let audioDataAsset = NSDataAsset(name: "BootSound") else {
            return
        }
        
#if !os(macOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.duckOthers])
        try? session.setActive(true, options: [])
#endif
        do {
            let audio = try AVAudioPlayer(data: audioDataAsset.data)
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
            BootGateView(isBootComplete: $ready) {
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
