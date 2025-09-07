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
import AppKit
#else
import MobileVLCKit
import UIKit
#endif

// Cross-platform aliases
#if os(macOS)
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformView = NSView
#else
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformView = UIView
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
    
    // MARK: Platform specific ViewRepresentable hooks
#if os(macOS)
    
    func makeNSView(context: Context) -> PlatformView {
        makePlatformView(context: context)
    }
    
    func updateNSView(_ nsView: PlatformView, context: Context) {
        updatePlatformView(nsView, context: context)
    }
    
    static func dismantleNSView(_ nsView: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
#else
    
    func makeUIView(context: Context) -> PlatformView {
        makePlatformView(context: context)
    }
    
    func updateUIView(_ uiView: PlatformView, context: Context) {
        updatePlatformView(uiView, context: context)
    }
    
    static func dismantleUIView(_ uiView: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
#endif
    
    //MARK: - Platform specific ViewRepresentable helpers
    
    private func makePlatformView(context: Context) -> PlatformView {
#if os(macOS)
        let view = PlatformView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
#else
        
        let view = PlatformView()
        view.backgroundColor = .black
#endif
        context.coordinator.attach(to: view)
        return view
    }
    
    private func updatePlatformView(_ view: PlatformView, context: Context) {
        
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
            //_player.delegate = self
            return _player
        }()
                
        func attach(to view: PlatformView) {
            mediaPlayer.drawable = view
        }
        
        func play(channel: GuideChannel) {
            
            if channel.url != mediaPlayer.media?.url {
                mediaPlayer.stop()
                //https://wiki.videolan.org/VLC_command-line_help/
//                let options: [String] = [
//                    "--no-video-title-show",
//                    "--avcodec-hw=any",             // prefer hardware decode when possible
//                    "--drop-late-frames",           // reduce CPU spikes under load
//                    "--skip-frames",                // allow frame skipping under pressure
//                    "--deinterlace=auto",           // try without deinterlace first (0, 1, auto)
//                    "--network-caching=1000",        // 1s; adjust for your latency vs CPU tradeoff
//                    "--live-caching=1000",
//                    "--no-lua"
//                ]
                
                let media = VLCMedia(url: channel.url)
                
                media.addOptions(["--network-caching": 1000,             // 1s; adjust for your latency vs CPU tradeoff
                                  "--live-caching": 1000,
                                  "--no-lua": 1,
                                  "--no-video-title-show": 1,
                                  "--avcodec-hw": "any",                  // prefer hardware decode when possible
                                  "--drop-late-frames": 1,                // reduce CPU spikes under load
                                  "--skip-frames": 1,                     // allow frame skipping under pressure
                                  "--deinterlace": 0                      // try without deinterlace first
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
