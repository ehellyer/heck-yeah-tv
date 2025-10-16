//
//  VLCPlayerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

#if os(tvOS)
import TVVLCKit
#elseif os(macOS)
import VLCKit
#elseif os(iOS)
import MobileVLCKit
#endif

struct VLCPlayerView: CrossPlatformRepresentable {

    //MARK: - Binding and State
    
    @Environment(\.scenePhase) private var scenePhase
    @Binding var appState: SharedAppState

    private var selectedChannelId: ChannelId? { appState.selectedChannel }
    
    //MARK: - CrossPlatformRepresentable overrides

    func makeCoordinator() -> VLCPlayerView.Coordinator {
        VLCPlayerView.Coordinator()
    }
    
    func makeView(context: Context) -> PlatformView {
        return context.coordinator.platformView
    }
    
    func updateView(_ view: PlatformView, context: Context) {
        // If app is not active, stop playback to release resources.
        if scenePhase != .active {
            context.coordinator.stop()
            return
        }
        
        // Reconciles the selectedChannelId and player state intent to determine the actual player state.
        context.coordinator.updatePlayState(channelId: selectedChannelId,
                                            shouldPause: appState.isPlayerPaused)
    }
    
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
    //MARK: - ViewRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {
        
        //MARK: - Private API
        
        private lazy var viewContext = DataPersistence.shared.viewContext
        
        private lazy var mediaPlayer: VLCMediaPlayer = {
            let _player = VLCMediaPlayer()
            _player.drawable = self.platformView
            _player.delegate = nil
            return _player
        }()
        
        private func resolveChannelURL(id: ChannelId) -> URL? {
            let predicate = #Predicate<IPTVChannel> { $0.id == id }
            var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
            descriptor.fetchLimit = 1
            return try? viewContext.fetch(descriptor).first?.url
        }
        
        //MARK: - Internal API
        
        // Platform view that VLC renders into
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
        
        //MARK: - Player controls

        /// Essentially this is the play() function, but it takes parameters to set player state based on channel selection and intent.
        /// - Parameters:
        ///   - channelId: (Optional) The identifier of the channel to play.
        ///   - shouldPause: Intent of the user to pause/resume an active playing stream.
        func updatePlayState(channelId: ChannelId?, shouldPause: Bool) {
            
            // Resolve desired channel URL from channelId
            let channelURL: URL? = {
                guard let channelId else { return nil }
                return self.resolveChannelURL(id: channelId)
            }()
            
            // If there is no channel URL, stop and clear media.
            guard let channelURL else {
                stop()
                return
            }
            
            let currentURL = mediaPlayer.media?.url
            let isCurrentlyPlaying = mediaPlayer.isPlaying
            
            // URL has changed, prepare new media and reconcile pause/play intent.
            if currentURL != channelURL {
                // Always stop before switching media.
                if isCurrentlyPlaying {
                    mediaPlayer.stop()
                }
                
                let media = VLCMedia(url: channelURL)
                // https://wiki.videolan.org/VLC_command-line_help/
                media.addOptions([
                    "network-caching": 1000,            // Network resource caching in milliseconds.
                    "no-lua": true,                     // Disable all lua plugins.
                    "no-video-title-show": true,        // Do not show media title on video.
                    "avcodec-hw": "any",                // Prefer hardware decode when possible. (reduce CPU)
                    "drop-late-frames": true,           // This drops frames that are late. (reduce CPU)
                    "skip-frames": true,                // allow frame skipping under pressure (reduce CPU)
                    "deinterlace": true                 // Turn deinterlace off to reduce CPU.
                ])
                mediaPlayer.media = media
                
                if shouldPause {
                    // Do not start playback; remain paused with new media loaded.
                    // VLC does not have a "paused but not started" state; simply refrain from play().
                } else {
                    mediaPlayer.play()
                }
                return
            }
            
            // URL is unchanged; reconcile pause/play intent.
            if shouldPause {
                if mediaPlayer.canPause, isCurrentlyPlaying {
                    mediaPlayer.pause()
                }
            } else {
                // Should be playing: if not already, start/resume.
                if !isCurrentlyPlaying {
                    mediaPlayer.play()
                }
            }
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
            guard mediaPlayer.canPause, mediaPlayer.isPlaying else { return }
            mediaPlayer.pause()
        }
        
        func stop() {
            if mediaPlayer.isPlaying {
                mediaPlayer.stop()
            }
            mediaPlayer.media = nil
        }
        
        func dismantle() {
            stop()
            mediaPlayer.drawable = nil
            mediaPlayer.delegate = nil
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
