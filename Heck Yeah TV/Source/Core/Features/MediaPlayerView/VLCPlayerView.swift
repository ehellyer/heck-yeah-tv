//
//  VLCPlayerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

#if os(tvOS)
import TVVLCKit
#elseif os(macOS)
import VLCKit
#elseif os(iOS)
import MobileVLCKit
#endif

@MainActor
struct VLCPlayerView: PlatformViewRepresentable {
    
    // Binding for selected channel
    @Binding var isPlaying: Bool
    @Binding var selectedChannel: GuideChannel?
    @Environment(\.scenePhase) private var scenePhase
    
    func makeCoordinator() -> VLCPlayerView.Coordinator {
        return VLCPlayerView.Coordinator()
    }
    
    // MARK: UIViewRepresentable overrides

#if os(macOS)
    func makeNSView(context: Context) -> PlatformView {
        makePlatformView(context: context)
    }
    
    func updateNSView(_ nsView: PlatformView, context: Context) {
        updatePlatformView(nsView, context: context)
    }
#else
    func makeUIView(context: Context) -> PlatformView {
        makePlatformView(context: context)
    }
    
    func updateUIView(_ view: PlatformView, context: Context) {
        updatePlatformView(view, context: context)
    }
#endif
    
    static func dismantleUIView(_ view: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
    //MARK: - Platform specific ViewRepresentable helpers
    
    private func makePlatformView(context: Context) -> PlatformView {
        print("makePlatformView(context:)")
        return context.coordinator.platformView
    }
    
    private func updatePlatformView(_ view: PlatformView, context: Context) {
        print("updatePlatformView(_ view:, context:)")
        if scenePhase != .active {
            context.coordinator.stop()
        }
        
        if not(isPlaying) {
            context.coordinator.pause()
        } else if isPlaying, scenePhase == .active, let channel = selectedChannel {
            context.coordinator.play(channel: channel)
        }
    }
    
    //MARK: - ViewRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {
        
        lazy var mediaPlayer = {
            let _player = VLCMediaPlayer()
            _player.drawable = self.platformView
            _player.delegate = nil
            return _player
        }()
        
        lazy var platformView: PlatformView = {
            let view = PlatformView()
#if os(macOS)
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.black.cgColor
#else
            view.backgroundColor = .black
#endif
            return view
        }()
        
        func play(channel: GuideChannel) {
            
            if channel.url != mediaPlayer.media?.url {
                mediaPlayer.stop()

                let media = VLCMedia(url: channel.url)
                //https://wiki.videolan.org/VLC_command-line_help/
                media.addOptions(["network-caching": 1000,              // 1s; adjust for your latency vs CPU tradeoff
                                  "live-caching": 1000,
                                  "no-lua": true,
                                  "no-video-title-show": true,
                                  "avcodec-hw": "any",                  // prefer hardware decode when possible
                                  "drop-late-frames": true,             // reduce CPU spikes under load
                                  "skip-frames": true,                  // allow frame skipping under pressure
                                  "deinterlace": false
                                 ])
                mediaPlayer.media = media
            }
            
            //If the player is currently playing, do nothing and return early.
            guard not(mediaPlayer.isPlaying) else {
                return
            }
            
            mediaPlayer.play()
        }
        
        func seekForward() {
            guard mediaPlayer.isSeekable else { return }
            mediaPlayer.jumpForward(2)
        }
        
        func seekBackward() {
            guard mediaPlayer.isSeekable else { return }
            mediaPlayer.jumpBackward(2)
        }
        
        func pause() {
            guard mediaPlayer.canPause else { return }
            mediaPlayer.pause()
        }
        
        func stop() {
            if mediaPlayer.isPlaying {
                mediaPlayer.stop()
            }
            mediaPlayer.media = nil
        }
        
        func dismantle() {
            mediaPlayer.drawable = nil
        }
    }
}

//MARK: - VLCMediaPlayerDelegate protocol

extension VLCPlayerView.Coordinator: VLCMediaPlayerDelegate {
    
    nonisolated func mediaPlayerStateChanged(_ aNotification: Notification) {
        //Not yet implemented
    }
    
    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        //Not yet implemented
    }
    
    nonisolated func mediaPlayerTitleChanged(_ aNotification: Notification) {
        //Not yet implemented
    }
    
    nonisolated func mediaPlayerChapterChanged(_ aNotification: Notification) {
        //Not yet implemented
    }
    
    nonisolated func mediaPlayerSnapshot(_ aNotification: Notification) {
        //Not yet implemented
    }
}
