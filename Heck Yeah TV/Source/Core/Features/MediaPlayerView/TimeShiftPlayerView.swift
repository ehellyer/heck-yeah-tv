//
//  TimeShiftPlayerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/14/25.
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

@MainActor
struct TimeShiftPlayerView: PlatformViewRepresentable {
    
    // Binding for selected channel
    @Binding var isPlaying: Bool
    @Binding var selectedChannel: GuideChannel?
    @Environment(\.scenePhase) private var scenePhase
    
    func makeCoordinator() -> TimeShiftPlayerView.Coordinator {
        return TimeShiftPlayerView.Coordinator()
    }
    
    // MARK: Platform specific ViewRepresentable hooks
#if os(macOS)
    
    func makeNSView(context: Context) -> PlatformView {
        return context.coordinator.platformView
    }
    
    func updateNSView(_ nsView: PlatformView, context: Context) {
        updatePlatformView(nsView, context: context)
    }
    
    static func dismantleNSView(_ nsView: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
#else
    
    func makeUIView(context: Context) -> PlatformView {
        return context.coordinator.mediaPlayer.platformView
    }
    
    func updateUIView(_ uiView: PlatformView, context: Context) {
        updatePlatformView(uiView, context: context)
    }
    
    static func dismantleUIView(_ uiView: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
#endif
    
    //MARK: - Platform specific ViewRepresentable helpers
    
    private func updatePlatformView(_ view: PlatformView, context: Context) {
        
        if scenePhase != .active {
            context.coordinator.stop()
        }
        
        if let channel = selectedChannel, channel.url != context.coordinator.mediaPlayer.mediaURL {
            context.coordinator.play(channel: channel)
        } else if not(isPlaying) {
            context.coordinator.pause()
        } else if isPlaying, scenePhase == .active, let channel = selectedChannel {
            if context.coordinator.mediaPlayer.state == PlayerState.pausedPlayback {
                context.coordinator.resume()
            } else if context.coordinator.mediaPlayer.state == .idle {
                context.coordinator.play(channel: channel)
            }
        }
    }
    
    //MARK: - ViewRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {
        
        lazy var mediaPlayer: TimeShiftEngine = TimeShiftEngine()
        
        func play(channel: GuideChannel) {
            if channel.url != mediaPlayer.mediaURL {
                mediaPlayer.start(streamURL: channel.url)
            }
        }
        
//        func seekForward() {
//            guard mediaPlayer.isSeekable else { return }
//            mediaPlayer.jumpForward(2)
//        }
//        
//        func seekBackward() {
//            guard mediaPlayer.isSeekable else { return }
//            mediaPlayer.jumpBackward(2)
//        }
        
        func resume() {
            mediaPlayer.resume()
        }
        
        func pause() {
            mediaPlayer.pause()
        }
        
        func stop() {
            mediaPlayer.stopAndDelete()
        }
        
        func dismantle() {
            mediaPlayer.stopAndDelete()
        }
    }
}

//MARK: - VLCMediaPlayerDelegate protocol

extension TimeShiftPlayerView.Coordinator: VLCMediaPlayerDelegate {
    
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
