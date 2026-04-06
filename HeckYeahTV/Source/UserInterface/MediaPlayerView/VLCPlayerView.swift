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
struct VLCPlayerView: View {
    
    //MARK: - Binding and State
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var isStreamUnplayable = false
    
    private var selectedChannel: Channel? { swiftDataController.selectedChannel }
    
    var body: some View {
        ZStack {
            VLCPlayerRepresentable(
                selectedChannel: selectedChannel,
                shouldPause: appState.isPlayerPaused,
                scenePhase: scenePhase,
                closedCaptionsEnabled: appState.closedCaptionsEnabled,
                selectedSubtitleTrackIndex: appState.selectedSubtitleTrackIndex,
                selectedAudioTrackIndex: appState.selectedAudioTrackIndex,
                playerVolume: appState.playerVolume,
                isStreamUnplayable: $isStreamUnplayable,
                appState: appState
            )
            .opacity(isStreamUnplayable ? 0 : 1)
            
            if isStreamUnplayable {
                UnplayableStreamOverlay()
            }
        }
    }
}

// MARK: - VLC Player Representable

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
    var appState: AppStateProvider
    
    //MARK: - CrossPlatformRepresentable overrides
    
    func makeCoordinator() -> VLCPlayerRepresentable.Coordinator {
        VLCPlayerRepresentable.Coordinator(
            isStreamUnplayable: $isStreamUnplayable,
            appState: appState
        )
    }
    
    func makeView(context: Context) -> PlatformView {
        return context.coordinator.platformView
    }
    
    func updateView(_ view: PlatformView, context: Context) {
        // Very course at the moment.  If the app is not active, stop the playback.
        context.coordinator.scenePhaseHandler(scenePhase)
        
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
        
        @Binding var isStreamUnplayable: Bool
        var appState: AppStateProvider
        
        init(isStreamUnplayable: Binding<Bool>, appState: AppStateProvider) {
            self._isStreamUnplayable = isStreamUnplayable
            self.appState = appState
            super.init()
        }
        //MARK: - Private API
        
        private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
        private let initVolume: Int32 = 120
        private var seekObservers: [NSObjectProtocol] = []
        private var lastTimeUpdate: Date?
        private var playbackStuckTimer: Task<Void, Never>?
        private var hasLoggedPlaybackStart = false
        private var errorRetryCount = 0
        private let maxErrorRetries = 3
        private var currentStreamURL: URL?
        
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
        ///   - channel: (Optional) The channel to play.
        ///   - shouldPause: Intent of the user to pause/resume an active playing stream.
        fileprivate func updatePlayState(channel: Channel?, shouldPause: Bool) {
            
            // Resolve desired channel URL from channelId
            
            
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
                    , "avcodec-hw": "none"                       // Disable hardware decoding, use software decoding only. Software decoder more flexible with format changes.
//                    , "avcodec-hw": "any"                      // Prefer hardware decode when possible (VideoToolbox on Apple). Reduces CPU load.
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
                        startPlaybackMonitoring()
                        mediaPlayer.play()
                    }
                }
                return
            }
            
            // URL is unchanged; reconcile pause/play intent.
            if shouldPause {
                if mediaPlayer.canPause, isCurrentlyPlaying {
                    logDebug("VLC: Pausing playback")
                    stopPlaybackMonitoring()
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
            logDebug("VLC: Stop requested")
            stopPlaybackMonitoring()
            if mediaPlayer.isPlaying {
                logDebug("VLC: Stopping active playback")
                mediaPlayer.stop()
            }
            mediaPlayer.media = nil
        }
        
        func clearVideoLayer() {
            // Clear the video layer to remove any frozen frame
#if os(macOS)
            if let layer = platformView.layer {
                layer.contents = nil
                layer.backgroundColor = PlatformColor.clear.cgColor
            }
#else
            platformView.layer.contents = nil
            platformView.backgroundColor = PlatformColor.clear
#endif
        }
        
        fileprivate func detectAndUpdateAvailableSubtitleTracks() {
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
        
        func detectAndUpdateAvailableAudioTracks() {
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
        
        func updateAudioTrack(index: Int32) {
            guard mediaPlayer.currentAudioTrackIndex != index else { return }
            logDebug("VLC: Switching to audio track index: \(index)")
            mediaPlayer.currentAudioTrackIndex = index
        }
        
        func updateVolume(_ volume: Int32) {
            guard let audio = mediaPlayer.audio else { return }
            guard audio.volume != volume else { return }
            logDebug("VLC: Setting volume to \(volume)")
            audio.volume = volume
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
        
        func dismantle() {
            stopPlaybackMonitoring()
            stop()
            mediaPlayer.drawable = nil
            mediaPlayer.delegate = nil
            platformView.removeFromSuperview()
        }
        
        // MARK: - Playback Monitoring
        
        /// Starts monitoring for stuck playback - if no time updates after 10 seconds, stream may be unplayable
        private func startPlaybackMonitoring() {
            hasLoggedPlaybackStart = false
            stopPlaybackMonitoring()
            
            playbackStuckTimer = Task { @MainActor in
                try? await Task.sleep(for: .seconds(10))
                
                guard !Task.isCancelled else { return }
                
                // Check if we've received any time updates
                if let lastUpdate = lastTimeUpdate {
                    let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
                    if timeSinceUpdate > 8 {
                        logError("VLC: WARNING - No playback progress for \(String(format: "%.1f", timeSinceUpdate))s - stream may be stuck or unplayable")
                        logError("VLC: Player state: \(mediaPlayer.state.rawValue), isPlaying: \(mediaPlayer.isPlaying)")
                    }
                } else if !hasLoggedPlaybackStart {
                    logError("VLC: WARNING - Playback did not start after 10 seconds - stream may be unplayable")
                    logError("VLC: Player state: \(mediaPlayer.state.rawValue), isPlaying: \(mediaPlayer.isPlaying)")
                    if let url = mediaPlayer.media?.url {
                        logError("VLC: Failed URL: \(url.absoluteString)")
                    }
                }
            }
        }
        
        /// Stops the playback monitoring task
        private func stopPlaybackMonitoring() {
            playbackStuckTimer?.cancel()
            playbackStuckTimer = nil
        }
        
        //MARK: - Scene phase handler
        
        fileprivate func scenePhaseHandler(_ scenePhase: ScenePhase) {
            
            if scenePhase != .active {
                stop()
                return
            }
            
            switch scenePhase {
                case .active:
                    logDebug("Player: App became active")
                case .inactive:
                    logDebug("Player: App became inactive")
                case .background:
                    logDebug("Player: App entered background")
                @unknown default:
                    logDebug("Player: Unknown scene phase")
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
            case .stopped:
                logDebug("VLC State: Stopped")
                Task { @MainActor in
                    self.stopPlaybackMonitoring()
                }
            case .opening:
                logDebug("VLC State: Opening stream...")
            case .buffering:
                logDebug("VLC State: Buffering")
            case .playing:
                logDebug("VLC State: Playing")
                Task { @MainActor in
                    // Playback started successfully, cancel stuck monitoring and reset error count
                    self.stopPlaybackMonitoring()
                    self.errorRetryCount = 0
                    self.isStreamUnplayable = false  // Clear unplayable indicator when playing
                    
                    // Wait 1 second for VLC to fully initialize tracks
                    try? await Task.sleep(for: .seconds(1))
                    
                    // Detect and populate available subtitle tracks
                    self.detectAndUpdateAvailableSubtitleTracks()
                    
                    // Detect and populate available audio tracks
                    self.detectAndUpdateAvailableAudioTracks()
                    
                    // Update seekable state
                    self.appState.isSeekable = player.isSeekable
                    logDebug("VLC: Stream is \(player.isSeekable ? "seekable" : "not seekable")")
                    
                    // Re-apply closed captions setting if enabled
                    // This ensures CC persists when switching channels
                    if self.appState.closedCaptionsEnabled {
                        self.updateClosedCaptions(enabled: true)
                    }
                }
            case .paused:
                logDebug("VLC State: Paused")
            case .ended:
                logError("VLC State: Ended - Stream closed unexpectedly or completed")
                if let url = player.media?.url {
                    logError("VLC: Stream that ended: \(url.absoluteString)")
                }
                Task { @MainActor in
                    self.stopPlaybackMonitoring()
                    self.errorRetryCount = 0  // Reset retry count
                    self.clearVideoLayer()  // Clear frozen frame
                    self.isStreamUnplayable = true  // Mark stream as unplayable
                }
            case .error:
                logError("VLC State: ERROR - Stream failed to play")
                logError("VLC: Media URL: \(player.media?.url?.absoluteString ?? "unknown")")
                
                Task { @MainActor in
                    self.stopPlaybackMonitoring()
                    
                    // Check if we should retry
                    self.errorRetryCount += 1
                    
                    if self.errorRetryCount <= self.maxErrorRetries {
                        logError("VLC: Retry attempt \(self.errorRetryCount) of \(self.maxErrorRetries)")
                        
                        // Attempt reconnect
                        Task { @MainActor [weak player] in
                            player?.stop()
                            try? await Task.sleep(for: .seconds(0.5))
                            player?.play()
                        }
                    } else {
                        logError("VLC: Max retry attempts (\(self.maxErrorRetries)) reached - stream is unplayable")
                        logError("VLC: Stopping further retry attempts to prevent infinite loop")
                        self.clearVideoLayer()  // Clear frozen frame
                        self.isStreamUnplayable = true  // Mark stream as unplayable
                        // Don't retry anymore - stream is genuinely unplayable
                    }
                }
            case .esAdded:
                logDebug("VLC State: Elementary Stream Added")
            @unknown default:
                logDebug("VLC State: Unknown state (\(state.rawValue))")
        }
    }
    
    nonisolated func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        
        Task { @MainActor in
            // Update last time we saw playback progressing
            self.lastTimeUpdate = Date()
            
            // Log first successful playback
            if !self.hasLoggedPlaybackStart && player.isPlaying {
                self.hasLoggedPlaybackStart = true
                if let timeValue = player.time.value {
                    let timeInSeconds = Double(timeValue.intValue) / 1000.0
                    logDebug("VLC: Playback started successfully (position: \(String(format: "%.1f", timeInSeconds))s)")
                } else {
                    logDebug("VLC: Playback started successfully")
                }
            }
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
