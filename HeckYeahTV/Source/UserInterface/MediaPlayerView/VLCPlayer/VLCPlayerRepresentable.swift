//
//  VLCPlayerRepresentable.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/8/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
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
struct VLCPlayerRepresentable: CrossPlatformRepresentable {
    
    let selectedChannel: Channel?
    let shouldPause: Bool
    let scenePhase: ScenePhase
    let closedCaptionsEnabled: Bool
    let selectedSubtitleTrackIndex: Int32?
    let selectedAudioTrackIndex: Int32?
    let playerVolume: Int32
    @Binding var isStreamUnplayable: Bool
    @Binding var isSwitchingStreams: Bool
    var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
    //MARK: - CrossPlatformRepresentable overrides
    
    func makeCoordinator() -> VLCPlayerRepresentable.Coordinator {
        VLCPlayerRepresentable.Coordinator(
            isStreamUnplayable: $isStreamUnplayable,
            isSwitchingStreams: $isSwitchingStreams,
            appState: appState
        )
    }
    
    func makeView(context: Context) -> PlatformView {
        return context.coordinator.platformView!
    }
    
    func updateView(_ view: PlatformView, context: Context) {
        // Very course at the moment.  If the app is not active, stop the playback.
        context.coordinator.scenePhaseHandler(scenePhase)
        
        // Check if the channel has changed - if so, ignore the unplayable flag to allow retry.
        let mediaPlayerCurrentURL = context.coordinator.currentStreamURL
        let selectedChannelURL = selectedChannel?.url
        
        // If stream is marked unplayable, don't try to play it, unless the channel is different, then ignore the unplayable flag.
        // This prevents an infinite retry loop when the monitoring timer marks a stream as unplayable
        guard (mediaPlayerCurrentURL != selectedChannelURL) || isStreamUnplayable == false else {
            context.coordinator.stop()
            return
        }
        
        // Reconciles the selectedChannelId and player state intent to determine the actual player state.
        context.coordinator.updatePlayState(channel: selectedChannel,
                                            shouldPause: shouldPause)
        
        // Update closed captions based on app state
        context.coordinator.updateClosedCaptions(enabled: closedCaptionsEnabled)
        
        // Update subtitle track if user selected one
        if let subtitleTrackIndex = selectedSubtitleTrackIndex, subtitleTrackIndex >= 0 {
            context.coordinator.updateSubtitleTrack(index: subtitleTrackIndex)
        }
        
        // Update audio track if user selected one
        if let audioTrackIndex = selectedAudioTrackIndex {
            context.coordinator.updateAudioTrack(index: audioTrackIndex)
        }
        
        // Update volume
        context.coordinator.updateVolume(playerVolume)
    }
    
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) {
        coordinator.dismantle()
    }
    
    //MARK: - ViewRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {
        
        init(isStreamUnplayable: Binding<Bool>,
             isSwitchingStreams: Binding<Bool>,
             appState: AppStateProvider) {
            self._isStreamUnplayable = isStreamUnplayable
            self._isSwitchingStreams = isSwitchingStreams
            self.appState = appState
            super.init()
        }
        
        //MARK: - Private API
        
        @Binding private var isStreamUnplayable: Bool
        @Binding private var isSwitchingStreams: Bool
        private var appState: AppStateProvider
        
        private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
        private let initVolume: Int32 = 120
        private var seekObservers: [NSObjectProtocol] = []
        private var lastTimeUpdate: Date?
        private var playbackStuckTimer: Task<Void, Never>?
        private var errorRetryCount = 0
        private let maxErrorRetries = 3
        fileprivate var currentStreamURL: URL?
        
        private lazy var mediaPlayer: VLCMediaPlayer = {
            let _player = VLCMediaPlayer()
            _player.drawable = newPlayerView()
            _player.delegate = self
            _player.audio?.volume = initVolume
            
//            let logger = VLCConsoleLogger()
//            logger.level = VLCLogLevel.warning
//            _player.libraryInstance.loggers = [logger]
            return _player
        }()
        
        private func newPlayerView() -> PlatformView {
            let view = PlatformView()
#if os(macOS)
            view.wantsLayer = true
            view.layer?.backgroundColor = PlatformColor.clear.cgColor
#else
            view.isUserInteractionEnabled = false
            view.backgroundColor = PlatformColor.clear
#endif
            return view
        }
        
        // Platform view that VLC renders into
        fileprivate var platformView: PlatformView? {
            return mediaPlayer.drawable as? PlatformView
        }
        
        //MARK: - Player controls
        
        /// Essentially this is the play() function, but it takes parameters to set player state based on channel selection and intent.
        /// - Parameters:
        ///   - channel: (Optional) The channel to play.
        ///   - shouldPause: Intent of the user to pause/resume an active playing stream.
        fileprivate func updatePlayState(channel: Channel?, shouldPause: Bool) {
            
            // If there is no channel URL, stop and clear media.
            guard let channelURL = channel?.url else {
                stop()
                return
            }
            
            let currentURL = mediaPlayer.media?.url
            let isCurrentlyPlaying = mediaPlayer.isPlaying
            
            // URL has changed, prepare new media and reconcile pause/play intent.
            if currentURL != channelURL {
                logDebug("VLC: Loading new channel URL: \(channelURL.absoluteString)")
                
                // Reset error retry count and unplayable state for new stream
                errorRetryCount = 0
                currentStreamURL = channelURL
                Task { @MainActor in
                    self.isStreamUnplayable = false
                }
                
                // Always stop before switching media.
                if isCurrentlyPlaying {
                    logDebug("VLC: Stopping current playback before switching")
                    mediaPlayer.stop()
                }
                
                // Dev Note: - EJH
                // Some streams (e.g. PlutoTV), are likely using #​EXT​-​X​-​DISCONTINUITY tags for ad insertion.  Ads might need to switch AV codec due to different resolutions required by the ad video stream.
                // My theory; this is causing VLC sometimes to do one of two things.
                //      1) freeze (the video is still frame and no audio), or
                //      2) loop back to the start of the previous chunk.  Sometimes replaying 5-10 minutes of video.
                // By trial and error I found these player options worked better in improving HLS adaptive streaming handling - (.ts) stream data packet mismatches (discontinuities).
                // But! It is not perfect. Still researching.
                
                let media = VLCMedia(url: channelURL)
                // https://wiki.videolan.org/VLC_command-line_help/
                
                media.addOptions([
                      "network-caching": 1000                    // Network resource caching in milliseconds. Increased to 15s to buffer through ad transitions.
                    , "http-reconnect": ""                       // Auto-reconnect on sudden stream drop. Default disabled; critical for live IPTV streams with unstable connections.
                    , "no-lua": ""                               // Disable all lua plugins. Boolean flags use empty string, not true/false.
//                    , "avcodec-hw": "none"                       // Disable hardware decoding, use software decoding only. Software decoder more flexible with format changes.
                    , "avcodec-hw": "any"                        // Prefer hardware decode when possible (VideoToolbox on Apple). Reduces CPU load.
                    , "avcodec-skiploopfilter": "all"            // Skip loop filter for all frames. More lenient decoding, helps with codec/format switching during ads.
                    , "avcodec-skip-frame": 0                    // Don't skip any frames. 0=AVDISCARD_NONE ensures all frames processed during discontinuities.
                    , "avcodec-skip-idct": 0                     // Don't skip IDCT. Ensures proper decoding through format changes.
                    , "avcodec-threads": 0                       // 0=auto thread count. Helps decoder handle format changes faster.
                    , "avcodec-fast": ""                         // Enable fast decoding. May help prevent stalls during transitions.
                    , "adaptive-logic": "highest"                // Start with highest quality variant, avoid low-res startup glitch. Options: rate, fixedrate, highest, lowest
                    , "adaptive-maxwidth": 3840                  // Max adaptive stream width. Set to 3840 for 4K support (1920 for Full HD).
                    , "adaptive-maxheight": 2160                 // Max adaptive stream height. Set to 2160 for 4K support (1080 for Full HD).
                    , "adaptive-bw": 15000000                    // Assume 15 Mbps bandwidth initially for 4K streams (2.5 Mbps for HD). Helps VLC pick higher quality at startup.
                    , "deinterlace": -1                          // -1 = Automatic: only deinterlaces when the stream signals it is interlaced. Most IPTV/HLS streams are progressive.
                    , "deinterlace-mode": "auto"                 // Auto-select the deinterlace algorithm when deinterlacing is active.
                    , "no-ts-trust-pcr": ""                      // Disable Trust in-stream PCR (default is enabled). Helps with HLS discontinuities.
                    , "ts-seek-percent": ""                      // Use percentage seeking instead of time-based. More reliable with discontinuous timestamps.
                    , "ts-extra-pmt": ""                         // Extra PMT for streams with multiple programs. Helps handle ad insertion as separate programs.
                    , "sout-ts-dts-delay": 400                   // Delay DTS (Decoding Time Stamp) by 400ms. Can help smooth transitions at discontinuities.
                    , "file-caching": 5000                       // File caching (ms) <integer [0 .. 60000]>
                    , "clock-jitter": 5000                       // Allow 10s clock jitter. Maximum tolerance for timestamp discontinuities at ad boundaries.
                    , "no-drop-late-frames": ""                  // Don't drop frames that arrive late. Prevents stalls from timing issues during transitions.
                    , "no-skip-frames": ""                       // Never skip frames even if behind. Prevents gaps during discontinuities.
                    , "avformat-format": "hls"                   // Explicitly tell avformat this is HLS. May improve discontinuity handling.
//                    , "no-cc-opaque": ""
//                    , "captions": 708
//                    , "preferred-resolution": 1080
//                    , "avcodec-debug": 1                         // FFmpeg debug mask: 1 = Detailed picture info, 2 = Rate Control details, 4 = Raw bit stream details. [https://www.ffmpeg.org/doxygen/0.6/avcodec_8h.html]
                ])
                mediaPlayer.media = media
                mediaPlayer.audio?.volume = initVolume
                
                if shouldPause {
                    logDebug("VLC: Media loaded but paused by user")
                    // Do not start playback; remain paused with new media loaded.
                    // VLC does not have a "paused but not started" state; simply refrain from play().
                } else {
                    if not(PreviewDetector.isRunningInPreview) {
                        logDebug("VLC: Starting playback")
                        mediaPlayer.play()
                    }
                }
                return
            }
            
            // URL is unchanged; reconcile pause/play intent.
            if shouldPause {
                if mediaPlayer.canPause, isCurrentlyPlaying {
                    logDebug("VLC: Pausing playback")
                    mediaPlayer.pause()
                }
            } else {
                // Should be playing: if not already, start/resume.
                if !isCurrentlyPlaying {
                    logDebug("VLC: Resuming playback")
                    if not(PreviewDetector.isRunningInPreview) {
                        startPlaybackMonitoring()
                        mediaPlayer.play()
                    }
                }
            }
        }
        
//        @objc private func seekForward() {
//            guard mediaPlayer.isSeekable else { return }
//            mediaPlayer.jumpForward(15)
//        }
//        
//        @objc private func seekBackward() {
//            guard mediaPlayer.isSeekable else { return }
//            mediaPlayer.jumpBackward(15)
//        }
        
        private func pause() {
            guard mediaPlayer.canPause, mediaPlayer.isPlaying else { return }
            mediaPlayer.pause()
        }
        
        fileprivate func stop() {
            logDebug("VLC: Stop requested")
            if mediaPlayer.isPlaying {
                logDebug("VLC: Stopping active playback")
                mediaPlayer.stop()
            }
            mediaPlayer.media = nil
        }
        
        fileprivate func updateVolume(_ volume: Int32) {
            guard let audio = mediaPlayer.audio else { return }
            guard audio.volume != volume else { return }
            logDebug("VLC: Setting volume to \(volume)")
            audio.volume = volume
        }
        
        fileprivate func dismantle() {
            stop()
            mediaPlayer.drawable = nil
            mediaPlayer.delegate = nil
            platformView?.removeFromSuperview()
        }

        
        //MARK: - Determine and configure Audio and Subtitle availability.
        
        fileprivate func updateClosedCaptions(enabled: Bool) {
            // Enable or disable subtitle tracks
            if enabled {
                // If user has selected a specific track, use that
                if let selectedIndex = appState.selectedSubtitleTrackIndex, selectedIndex >= 0 {
                    logDebug("VLC: Enabling selected subtitle track (index: \(selectedIndex))")
                    mediaPlayer.currentVideoSubTitleIndex = selectedIndex
                    return
                }
                
                // Otherwise, try to auto-select a track
                let validTracks = appState.availableSubtitleTracks
                if !validTracks.isEmpty {
                    // Try to match user's preferred language
                    if let preferredLanguages = Locale.preferredLanguages.first {
                        let preferredCode = String(preferredLanguages.prefix(2)).lowercased()
                        if let matchingTrack = validTracks.first(where: { $0.languageCode == preferredCode }) {
                            logDebug("VLC: Auto-selecting subtitle track matching language \(preferredCode): \(matchingTrack.name)")
                            mediaPlayer.currentVideoSubTitleIndex = matchingTrack.index
                            appState.selectedSubtitleTrackIndex = matchingTrack.index
                            return
                        }
                    }
                    
                    // No language match, use first track
                    if let firstTrack = validTracks.first {
                        logDebug("VLC: Enabling first subtitle track (index: \(firstTrack.index))")
                        mediaPlayer.currentVideoSubTitleIndex = firstTrack.index
                        appState.selectedSubtitleTrackIndex = firstTrack.index
                    }
                } else {
                    logDebug("VLC: No valid subtitle tracks available to enable")
                    // Show toast notification and disable CC
                    ToastManager.shared.show("No subtitles available")
                    appState.closedCaptionsEnabled = false
                    appState.selectedSubtitleTrackIndex = nil
                }
            } else {
                // Disable subtitles by setting index to -1
                logDebug("VLC: Disabling closed captions")
                mediaPlayer.currentVideoSubTitleIndex = -1
                appState.selectedSubtitleTrackIndex = nil
            }
        }
        
        fileprivate func updateSubtitleTrack(index: Int32) {
            guard mediaPlayer.currentVideoSubTitleIndex != index else { return }
            logDebug("VLC: Switching to subtitle track index: \(index)")
            mediaPlayer.currentVideoSubTitleIndex = index
        }
        
        fileprivate func updateAudioTrack(index: Int32) {
            guard mediaPlayer.currentAudioTrackIndex != index else { return }
            logDebug("VLC: Switching to audio track index: \(index)")
            mediaPlayer.currentAudioTrackIndex = index
        }
        
        private func updateAvailableAudioAndSubtitleTracks() {
            Task { @MainActor [weak self] in
                
                // Wait 1 second for VLC to fully initialize stream.
                try? await Task.sleep(for: .seconds(1))
                
                guard let self else { return }
                
                // Detect and populate available subtitle tracks
                self.detectAndUpdateAvailableSubtitleTracks()
                
                // Detect and populate available audio tracks
                self.detectAndUpdateAvailableAudioTracks()
                
                // Re-apply closed captions setting if enabled
                // This ensures CC persists when switching channels
                if self.appState.closedCaptionsEnabled {
                    self.updateClosedCaptions(enabled: true)
                }
            }
        }
        
        private func detectAndUpdateAvailableSubtitleTracks() {
            // Get available subtitle tracks from VLC
            guard let subtitleIndexes = mediaPlayer.videoSubTitlesIndexes as? [Int] else {
                logDebug("VLC: videoSubTitlesIndexes is nil or wrong type")
                appState.availableSubtitleTracks = []
                appState.selectedSubtitleTrackIndex = nil
                return
            }
            
            logDebug("VLC: Found subtitle indexes: \(subtitleIndexes)")
            
            // Try to get names if available, otherwise use generic names
            let subtitleNames: [String]
            if let names = mediaPlayer.videoSubTitlesNames as? [String] {
                logDebug("VLC: Found subtitle names: \(names)")
                subtitleNames = names
            } else {
                logDebug("VLC: videoSubTitlesNames not available, using generic names")
                // Generate generic names based on index
                subtitleNames = subtitleIndexes.map { index in
                    if index == -1 {
                        return "Disable"
                    } else {
                        return "Track \(index)"
                    }
                }
            }
            
            // Filter out the "Disable" track (index -1) if present
            let validTracks = zip(subtitleIndexes, subtitleNames)
                .filter { $0.0 >= 0 }
                .map { TrackItem(id: Int32($0.0), index: Int32($0.0), name: $0.1) }
            
            if let firstTrack = validTracks.first {
                appState.availableSubtitleTracks = [firstTrack]
            } else {
                appState.availableSubtitleTracks = []
            }
            
            // Get current subtitle track
            let currentIndex = mediaPlayer.currentVideoSubTitleIndex
            appState.selectedSubtitleTrackIndex = currentIndex >= 0 ? currentIndex : nil
            
            logDebug("VLC: Detected \(validTracks.count) subtitle tracks, current: \(currentIndex)")
        }
        
        private func detectAndUpdateAvailableAudioTracks() {
            // Get available audio tracks from VLC
            guard let audioTrackIndexes = mediaPlayer.audioTrackIndexes as? [Int],
                  let audioTrackNames = mediaPlayer.audioTrackNames as? [String] else {
                logDebug("VLC: No audio tracks available")
                appState.availableAudioTracks = []
                appState.selectedAudioTrackIndex = nil
                return
            }
            
            // Filter out the "Disable" track (index -1) if present
            let validTracks = zip(audioTrackIndexes, audioTrackNames)
                .filter { $0.0 >= 0 }
                .map { TrackItem(id: Int32($0.0), index: Int32($0.0), name: $0.1) }
            
            appState.availableAudioTracks = validTracks
            
            // Get current audio track
            let currentIndex = mediaPlayer.currentAudioTrackIndex
            appState.selectedAudioTrackIndex = currentIndex >= 0 ? currentIndex : nil
            
            logDebug("VLC: Detected \(validTracks.count) audio tracks, current: \(currentIndex)")
            
            // Auto-select preferred language track if this is a new stream and no selection made yet
            if appState.selectedAudioTrackIndex == nil && !validTracks.isEmpty {
                selectPreferredAudioTrack(from: validTracks)
            }
        }
        
        private func selectPreferredAudioTrack(from tracks: [TrackItem]) {
            // Get user's preferred language from Locale
            let preferredLanguages = Locale.preferredLanguages
            guard let primaryLanguage = preferredLanguages.first else {
                // No preference, use first track
                if let firstTrack = tracks.first {
                    logDebug("VLC: No language preference, selecting first track: \(firstTrack.name)")
                    updateAudioTrack(index: firstTrack.index)
                }
                return
            }
            
            // Extract language code from preferred language (e.g., "en-US" -> "en")
            let preferredCode = String(primaryLanguage.prefix(2)).lowercased()
            
            // Try to find a matching track by language code
            if let matchingTrack = tracks.first(where: { $0.languageCode == preferredCode }) {
                logDebug("VLC: Found preferred language track (\(preferredCode)): \(matchingTrack.name)")
                updateAudioTrack(index: matchingTrack.index)
                return
            }
            
            // No match found, use first track as default
            if let firstTrack = tracks.first {
                logDebug("VLC: No matching language track for \(preferredCode), using first track: \(firstTrack.name)")
                updateAudioTrack(index: firstTrack.index)
            }
        }
                
        // MARK: - Playback Monitoring
        
        private let playerWatchdog = Watchdog()
        
        private func startPlaybackMonitoring() {
            self.lastTimeUpdate = Date()
            Task {
                await playerWatchdog.start { @MainActor [weak self] in
                    
                    guard let self, let lastUpdate = self.lastTimeUpdate else {
                        //Invalid state - stop watchdog.
                        return false
                    }
                    
                    // Check if we've received any time updates
                    
                    let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
                    if timeSinceUpdate > 7 && self.appState.isPlayerPaused == false {
                        logError("VLC: ERROR - No playback progress for \(String(format: "%.1f", timeSinceUpdate))s - marking stream as unplayable")
                        logError("VLC: Player state: \(self.mediaPlayer.state.rawValue), isPlaying: \(self.mediaPlayer.isPlaying)")
                        if let url = self.mediaPlayer.media?.url {
                            logError("VLC: Failed URL: \(url.absoluteString)")
                        }
                        
                        // Mark stream as unplayable and stop playback
                        self.isStreamUnplayable = true
                        self.isSwitchingStreams = false
                        
                        // Stop watchdog.
                        return false
                    } else {
                        // Stay on patrol.  Not yet reached max time.
                        return true
                    }
                }
            }
        }
        
        private func stopPlaybackMonitoring() {
            self.isSwitchingStreams = false
            Task {
                await playerWatchdog.stop()
            }
        }
        
        //MARK: - Scene phase handler
        
        fileprivate func scenePhaseHandler(_ scenePhase: ScenePhase) {
            
            switch scenePhase {
                case .active:
                    logDebug("Player: App scene phase is active.")
                case .inactive:
                    logDebug("Player: App scene phase is inactive.")
                case .background:
                    logDebug("Player: App scene phase is in background.")
                @unknown default:
                    logDebug("Player: Unknown scene phase.")
            }

            if scenePhase != .active {
                stop()
                return
            }
        }
    }
}

//MARK: - VLCMediaPlayerDelegate protocol

extension VLCPlayerRepresentable.Coordinator: VLCMediaPlayerDelegate {

    
    nonisolated func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        let state = player.state
        
        // Log all state changes for debugging
        switch state {
 
            case .opening:
                logDebug("VLC State: Opening stream...")
                Task { @MainActor in
                    self.isSwitchingStreams = true
                    self.startPlaybackMonitoring()
                }
                
            case .esAdded:
                // Elementary Stream added
                logDebug("VLC State: Elementary Stream Added")
                
            case .buffering:
                logDebug("VLC State: Buffering")
                Task { @MainActor in
                    self.lastTimeUpdate = Date()
                }
                
            case .playing:
                logDebug("VLC State: Playing")
                Task { @MainActor in
                    // Playback started successfully, cancel stuck monitoring and reset error count
                    self.errorRetryCount = 0
                    self.isSwitchingStreams = false
                    self.isStreamUnplayable = false  // Clear unplayable indicator when playing
                    self.updateAvailableAudioAndSubtitleTracks()
                }
                
            case .paused:
                logDebug("VLC State: Paused")
                Task { @MainActor in
                    self.stopPlaybackMonitoring()
                }

            case .stopped:
                logDebug("VLC State: Stopped")
                Task { @MainActor in
                    self.stopPlaybackMonitoring()
                }
                
            case .ended:
                logWarning("VLC State: Ended - Stream closed unexpectedly or completed")
                if let url = player.media?.url {
                    logDebug("VLC: Stream that ended: \(url.absoluteString)")
                }
                Task { @MainActor in
                    self.stopPlaybackMonitoring()
                    self.errorRetryCount = 0  // Reset retry count
                }
                
            case .error:
                logError("VLC State: ERROR - Stream failed to play")
                logError("VLC: Media URL: \(player.media?.url?.absoluteString ?? "unknown")")
                
                Task { @MainActor in
                    // Check if we should retry
                    self.errorRetryCount += 1
                    
                    if self.errorRetryCount <= self.maxErrorRetries {
                        logError("VLC: Retry attempt \(self.errorRetryCount) of \(self.maxErrorRetries)")
                        
                        // Attempt reconnect - restart monitoring for this retry
                        Task { @MainActor [weak player] in
                            player?.stop()
                            try? await Task.sleep(for: .seconds(0.5))
                            player?.play()
                        }
                    } else {
                        logError("VLC: Max retry attempts (\(self.maxErrorRetries)) reached - stream is unplayable")
                        logError("VLC: Stopping further retry attempts to prevent infinite loop")
                        self.isStreamUnplayable = true
                        self.isSwitchingStreams = false
                    }
                }
                
            @unknown default:
                logWarning("VLC State: Unknown state (\(state.rawValue))")
        }
    }
    
    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        Task { @MainActor in
            // Update last time we saw playback progressing
            self.lastTimeUpdate = Date()
        }
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
