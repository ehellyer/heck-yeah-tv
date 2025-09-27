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

struct VLCPlayerView: UnifiedPlatformRepresentable {
    
    //MARK: - Binding and State
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(GuideStore.self) private var guideStore
    
    //MARK: - UnifiedPlatformRepresentable overrides

    func makeCoordinator() -> VLCPlayerView.Coordinator {
        return VLCPlayerView.Coordinator()
    }
    
    func makeView(context: Context) -> PlatformView {
        return context.coordinator.platformView
    }
    
    func updateView(_ view: PlatformView, context: Context) {
        if scenePhase != .active {
            context.coordinator.stop()
            Task {
                await guideStore.flushSavesNow()
            }
        }
        
        if not(guideStore.isPlaying) {
            context.coordinator.pause()
        } else if guideStore.isPlaying, scenePhase == .active, let channel = guideStore.selectedChannel {
            context.coordinator.play(channel: channel)
        }
    }
    
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
    //MARK: - ViewRepresentable Coordinator
    
    final class Coordinator: NSObject {
        
        lazy var mediaPlayer = {
            let _player = VLCMediaPlayer()
            _player.drawable = self.platformView
            _player.delegate = nil
            return _player
        }()
        
        lazy var platformView: PlatformView = {
            let view = PlatformUtils.createView()

#if os(macOS)
            view.wantsLayer = true
            view.layer?.backgroundColor = PlatformColor.black.cgColor
#else
            view.isUserInteractionEnabled = false
            view.backgroundColor = PlatformColor.black
#endif
            return view
        }()
        
        func play(channel: GuideChannel) {
            
            if channel.url != mediaPlayer.media?.url {
                mediaPlayer.stop()

                let media = VLCMedia(url: channel.url)
                //https://wiki.videolan.org/VLC_command-line_help/
                media.addOptions(["network-caching": 1000,              // 1s;
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
            platformView.removeFromSuperview()
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
