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


struct VLCPlayerView: PlatformViewRepresentable {
    
    // Binding for selected channel
    @Binding var channel: GuideChannel?
    @Binding var screenPhase: ScenePhase
    
    
    func makeCoordinator() -> VLCPlayerView.Coordinator {
        return VLCPlayerView.Coordinator(scenePhase: screenPhase)
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
        if screenPhase == .active, let channel {
            context.coordinator.play(channel: channel)
        }
        
        if screenPhase != .active {
            context.coordinator.stop()
        }
    }
    
    //MARK: - ViewRepresentable Coordinator
    
    final class Coordinator: NSObject {
        
        private lazy var mediaPlayer = VLCMediaPlayer()
        private var scenePhase: ScenePhase
        
        init(scenePhase: ScenePhase) {
            self.scenePhase = scenePhase
        }
        
        func attach(to view: PlatformView) {
            mediaPlayer.drawable = view
        }
        
        func play(channel: GuideChannel) {
            //If we are requesting to play the same channel and the player is currently playing, do nothing and return early.
            guard not(channel.url == mediaPlayer.media?.url && mediaPlayer.isPlaying) else {
                return
            }
            let media = VLCMedia(url: channel.url)
            // Buffer 500ms before playing the stream.
            media.addOptions(["network-caching": 500])
            mediaPlayer.media = media
            mediaPlayer.delegate = self
            mediaPlayer.play()
        }
        
        func seekForward() {
            guard mediaPlayer.isSeekable else { return }
            mediaPlayer.position = min(1.0, mediaPlayer.position * 1.01)
        }
        
        func seekBackward() {
            guard mediaPlayer.isSeekable else { return }
            mediaPlayer.position = max(0.0, mediaPlayer.position * -1.01)
        }
        
        func pause() {
            guard mediaPlayer.canPause else { return }
            mediaPlayer.pause()
        }
        
        func stop() {
            if mediaPlayer.isPlaying {
                mediaPlayer.stop()
                mediaPlayer.media = nil
            }
        }
        
        func dismantle() {
            mediaPlayer.drawable = nil
        }
    }
}

//MARK: - VLCMediaPlayerDelegate protocol

extension VLCPlayerView.Coordinator: VLCMediaPlayerDelegate {
    
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        
    }
    
    func mediaPlayerTitleChanged(_ aNotification: Notification) {
        
    }
    
    func mediaPlayerChapterChanged(_ aNotification: Notification) {
        
    }
    
    func mediaPlayerSnapshot(_ aNotification: Notification) {
        
    }
}
