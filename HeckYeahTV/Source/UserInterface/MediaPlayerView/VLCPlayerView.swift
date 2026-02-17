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

@MainActor
struct VLCPlayerView: CrossPlatformRepresentable {

    //MARK: - Binding and State
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
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

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        override init() {
            super.init()
            registerObservers()
        }
        
        //MARK: - Private API
        private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
        private let initVolume: Int32 = 120
        private var seekObservers: [NSObjectProtocol] = []
        
        private lazy var mediaPlayer: VLCMediaPlayer = {
            let _player = VLCMediaPlayer()
            _player.drawable = self.platformView
            _player.delegate = self
            _player.audio?.volume = initVolume
            
            return _player
        }()
        
        private func resolveChannelURL(id: ChannelId) -> URL? {
            let channel = try? swiftDataController.channel(for: id)
            return channel?.url
        }
        
        private func registerObservers() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(seekForward),
                                                   name: .playerSeekForward,
                                                   object: nil)
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(seekBackward),
                                                   name: .playerSeekBackward,
                                                   object: nil)
        }
        
        //MARK: - Internal API
        
        // Platform view that VLC renders into
        lazy var platformView: PlatformView = {
            let view = PlatformView()
#if os(macOS)
            view.wantsLayer = true
            view.layer?.backgroundColor = PlatformColor.clear.cgColor
#else
            view.isUserInteractionEnabled = false
            view.backgroundColor = PlatformColor.clear
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
                    "network-caching": 2000,            // Network resource caching in milliseconds. Range: 0–60000. Keep low for live streams to reduce signed-URL expiry risk.
                    "http-reconnect": "",               // Auto-reconnect on sudden stream drop. Default disabled; critical for live IPTV streams with unstable connections.
                    "no-lua": "",                       // Disable all lua plugins. Boolean flags use empty string, not true/false.
                    "avcodec-hw": "any",                // Prefer hardware decode when possible (VideoToolbox on Apple). Reduces CPU load.
                    "deinterlace": -1,                  // -1 = Automatic: only deinterlaces when the stream signals it is interlaced. Most IPTV/HLS streams are progressive.
                    "deinterlace-mode": "auto",         // Auto-select the deinterlace algorithm when deinterlacing is active.
                    // Note: drop-late-frames and skip-frames are both enabled by default; no need to set them explicitly.
                    // Note: video-title-show is disabled by default; no need to set it explicitly.
                    // Note: video-filter "deinterlace" removed — redundant with deinterlace: -1 and causes double processing.
                ])
                mediaPlayer.media = media
                mediaPlayer.audio?.volume = initVolume
                
                if shouldPause {
                    // Do not start playback; remain paused with new media loaded.
                    // VLC does not have a "paused but not started" state; simply refrain from play().
                } else {
                    if not(PreviewDetector.isRunningInPreview) {
                        mediaPlayer.play()
                    }
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
                    if not(PreviewDetector.isRunningInPreview) {
                        mediaPlayer.play()
                    }
                }
            }
        }
        
        @objc func seekForward() {
            guard mediaPlayer.isSeekable else { return }
            mediaPlayer.jumpForward(15)
        }
        
        @objc func seekBackward() {
            guard mediaPlayer.isSeekable else { return }
            mediaPlayer.jumpBackward(15)
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
        //logDebug("VLCPlayerView.Coordinator:mediaPlayerStateChanged ☀️")

        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        let state = player.state
        switch state {
            case .error:
                
                logDebug("VLCPlayerView.Coordinator:mediaPlayerStateChanged error ☀️")
//                // Stream errored — attempt reconnect by replaying the same media
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak player] in
//                    player?.play()
//                }
            default:
                break
        }
    }
    
    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        //Not yet implemented
//        logDebug("VLCPlayerView.Coordinator:mediaPlayerTimeChanged ☀️")
    }
    
    nonisolated func mediaPlayerTitleChanged(_ aNotification: Notification) {
        //Not yet implemented
        logDebug("VLCPlayerView.Coordinator:mediaPlayerTitleChanged ☀️")
    }
    
    nonisolated func mediaPlayerChapterChanged(_ aNotification: Notification) {
        //Not yet implemented
        logDebug("VLCPlayerView.Coordinator:mediaPlayerChapterChanged ☀️")
    }
    
    nonisolated func mediaPlayerSnapshot(_ aNotification: Notification) {
        //Not yet implemented
        logDebug("VLCPlayerView.Coordinator:mediaPlayerSnapshot ☀️")
    }
}
