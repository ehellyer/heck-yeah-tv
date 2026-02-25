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
@preconcurrency import TVVLCKit
#elseif os(macOS)
@preconcurrency import VLCKit
#elseif os(iOS)
@preconcurrency import MobileVLCKit
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
//            let logger = VLCConsoleLogger()
//            logger.level = VLCLogLevel.warning
//            _player.libraryInstance.loggers = [logger]
            return _player
        }()
        
        private func resolveChannelURL(id: ChannelId) -> URL? {
            let channel = swiftDataController.channel(for: id)
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
                
                // Dev Note: - EJH
                // Some streams (e.g. PlutoTV), are likely using #​EXT​-​X​-​DISCONTINUITY tags for ad insertion.  Ads might need to switch avcodec due to different resolutions required by the ad video stream.
                // My theory; this is causing VLC sometimes to do one of two things.
                //      1) freeze (the video is still frame and no audio), or
                //      2) loop back to the start of the previous chunk.
                // By trial and error I found these player options worked better in improving HLS adaptive streaming handling - (.ts) stream data packet mismatches (discontinuities).
                // But! It is not perfect. Still researching.
                
                let media = VLCMedia(url: channelURL)
                // https://wiki.videolan.org/VLC_command-line_help/
                media.addOptions([
                    "network-caching": 15000,           // Network resource caching in milliseconds. Increased to 15s to buffer through ad transitions.
                    "http-reconnect": "",               // Auto-reconnect on sudden stream drop. Default disabled; critical for live IPTV streams with unstable connections.
                    "no-lua": "",                       // Disable all lua plugins. Boolean flags use empty string, not true/false.
                    "avcodec-hw": "none",               // Disable hardware decoding, use software decoding only. Software decoder more flexible with format changes.
                    "avcodec-skiploopfilter": "all",    // Skip loop filter for all frames. More lenient decoding, helps with codec/format switching during ads.
                    "avcodec-skip-frame": 0,            // Don't skip any frames. 0=AVDISCARD_NONE ensures all frames processed during discontinuities.
                    "avcodec-skip-idct": 0,             // Don't skip IDCT. Ensures proper decoding through format changes.
                    "avcodec-threads": 0,               // 0=auto thread count. Helps decoder handle format changes faster.
                    "avcodec-fast": "",                 // Enable fast decoding. May help prevent stalls during transitions.
                    "adaptive-logic": "rate",           // Use rate-based adaptive logic for HLS quality selection. May handle discontinuities better than default.
                    "adaptive-maxwidth": 1920,          // Max adaptive stream width. Prevents unexpected quality jumps during ads.
                    "adaptive-maxheight": 1080,         // Max adaptive stream height.
                    "deinterlace": -1,                  // -1 = Automatic: only deinterlaces when the stream signals it is interlaced. Most IPTV/HLS streams are progressive.
                    "deinterlace-mode": "auto",         // Auto-select the deinterlace algorithm when deinterlacing is active.
                    "no-ts-trust-pcr": "",              // Disable Trust in-stream PCR (default is enabled). Helps with HLS discontinuities.
                    "ts-seek-percent": "",              // Use percentage seeking instead of time-based. More reliable with discontinuous timestamps.
                    "ts-extra-pmt": "",                 // Extra PMT for streams with multiple programs. Helps handle ad insertion as separate programs.
                    "sout-ts-dts-delay": 400,           // Delay DTS (Decoding Time Stamp) by 400ms. Can help smooth transitions at discontinuities.
                    "file-caching": 5000,               // File caching (ms) <integer [0 .. 60000]>
                    "clock-jitter": 10000,              // Allow 10s clock jitter. Maximum tolerance for timestamp discontinuities at ad boundaries.
                    "no-drop-late-frames": "",          // Don't drop frames that arrive late. Prevents stalls from timing issues during transitions.
                    "no-skip-frames": "",               // Never skip frames even if behind. Prevents gaps during discontinuities.
                    "avformat-format": "hls"            // Explicitly tell avformat this is HLS. May improve discontinuity handling.
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
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        let state = player.state
        switch state {
            case .error:
                logError("VLCPlayerView.Coordinator:mediaPlayerStateChanged error.")
                // Stream errored — attempt reconnect by replaying the same media
                Task { @MainActor [weak player] in
                    player?.stop()
                    try? await Task.sleep(for: .seconds(0.5))
                    player?.play()
                }
            default:
                break
        }
    }
    
    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        //Not yet implemented
//        logDebug("VLCPlayerView.Coordinator:mediaPlayerTimeChanged")
    }
    
    nonisolated func mediaPlayerTitleChanged(_ aNotification: Notification) {
        //Not yet implemented
        logDebug("VLCPlayerView.Coordinator:mediaPlayerTitleChanged")
    }
    
    nonisolated func mediaPlayerChapterChanged(_ aNotification: Notification) {
        //Not yet implemented
        logDebug("VLCPlayerView.Coordinator:mediaPlayerChapterChanged")
    }
    
    nonisolated func mediaPlayerSnapshot(_ aNotification: Notification) {
        //Not yet implemented
        logDebug("VLCPlayerView.Coordinator:mediaPlayerSnapshot")
    }
}
