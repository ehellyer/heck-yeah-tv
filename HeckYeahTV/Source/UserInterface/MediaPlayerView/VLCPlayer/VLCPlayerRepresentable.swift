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
        // Very course at the moment.  If the app is not active, stop the playback, return early.
        if scenePhase != .active {
            context.coordinator.stop()
            return
        }
        
        // Check if the channel has changed - if so, ignore the unplayable flag to allow retry.
        let mediaPlayerCurrentURL = context.coordinator.currentStreamURL
        let selectedChannelURL = selectedChannel?.url
        
        // If stream is marked unplayable for the current channel, then stop and exit.  (unless the channel is different, then ignore the unplayable flag).
        if (mediaPlayerCurrentURL == selectedChannelURL && isStreamUnplayable) {
            context.coordinator.stop()
            return
        }
        
        // Reconciles the selectedChannelId and player state intent to determine the actual player state.
        context.coordinator.updatePlayState(channel: selectedChannel,
                                            shouldPause: shouldPause)
        
        // Update closed captions
        context.coordinator.updateClosedCaptions()
        
        // Update audio track if user selected one
        context.coordinator.updateAudioTrack()
        
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
        private var seekObservers: [NSObjectProtocol] = []
        private var lastTimeUpdate: Date?
        private var playbackStuckTimer: Task<Void, Never>?
        private var errorRetryCount = 0
        private let maxErrorRetries = 3
        fileprivate var currentStreamURL: URL?

        // Mid-stream stall recovery (e.g. VLC stuck buffering after an HLS ad-break discontinuity).
        // See "Dev Note: - VLC playback watchdog" in the Playback Monitoring section.
        private var hasReachedPlaying = false
        private var stallRecoveryCount = 0
        private let maxStallRecoveries = 3
        private var lastStallRecoveryDate: Date?
        // Healthy playback needed after a reload before the recovery budget resets.
        // Ad breaks put a discontinuity every 30-60s, so this must be shorter than a single ad.
        private let stallRecoveryResetInterval: TimeInterval = 20
        private var isReloadingStream = false

        // Stall thresholds (seconds without playback progress).
        // Startup: stream opening/connecting, until the first real playback progress (also applies right after a reload).
        private let startupStallThreshold: TimeInterval = 7
        // Mid-stream: once playback has progressed, a stall this long is treated as frozen (e.g. ad-break discontinuity).
        private let midStreamStallThreshold: TimeInterval = 3
        // Last playback time (ms) reported by VLC; used to tell real progress from repeated time-changed events.
        // nil until the stream has actually progressed, which is also how startup is distinguished from mid-stream.
        private var lastPlaybackTime: Int32?

        // Delayed lookup of available audio/subtitle tracks after playback starts.
        private var trackAvailabilityTask: Task<Void, Never>?
        private let maxTrackAvailabilityAttempts = 5

        // When true, forces VLC to use the avcodec (software) decoder ahead of its VideoToolbox decoder module.
        // Note: "avcodec-hw: none" alone does not do this - VLC's separate videotoolbox module has higher priority.
        // Set to false if CPU/thermal load is too high (e.g. 4K on Apple TV).
        private let forceSoftwareDecode = true
        
        private lazy var mediaPlayer: VLCMediaPlayer = {
            let _player = VLCMediaPlayer()
            _player.drawable = newPlayerView()
            _player.delegate = self
            _player.audio?.volume = appState.playerVolume
            
#if DEBUG
            // libVLC internal logging (adaptive/HLS demux, TS, clock, decoders).
            // .error for day-to-day work. Switch to .debug (very verbose) to diagnose stalls - e.g. look for
            // "Ending demuxer stream. [discontinuity]" and a frozen "cur" value in "cached.i_time" lines.
            let logger = VLCConsoleLogger()
            logger.level = VLCLogLevel.error
            _player.libraryInstance.loggers = [logger]
#endif
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
                hasReachedPlaying = false
                stallRecoveryCount = 0
                lastStallRecoveryDate = nil
                lastPlaybackTime = nil
                isReloadingStream = false
                resetAudioTrackState()
                Task { @MainActor in
                    self.isStreamUnplayable = false
                }
                
                
                // Always stop before switching media.
                if isCurrentlyPlaying {
                    logDebug("VLC: Stopping current playback before switching")
                    mediaPlayer.stop()
                }

                mediaPlayer.media = makeMedia(url: channelURL)

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

        /// Builds a new VLCMedia for the given URL with the player options tuned for live HLS/IPTV streams.
        private func makeMedia(url: URL) -> VLCMedia {

            // Dev Note: - EJH
            // Some streams (e.g. PlutoTV), are likely using #​EXT​-​X​-​DISCONTINUITY tags for ad insertion.  Ads might need to switch AV codec due to different resolutions required by the ad video stream.
            // My theory; this is causing VLC sometimes to do one of two things.
            //      1) freeze (the video is still frame and no audio), or
            //      2) loop back to the start of the previous chunk.  Sometimes replaying 5-10 minutes of video.
            // By trial and error I found these player options worked better in improving HLS adaptive streaming handling - (.ts) stream data packet mismatches (discontinuities).
            // But! It is not perfect. Still researching.

            let media = VLCMedia(url: url)
            // https://wiki.videolan.org/VLC_command-line_help/

            var options: [AnyHashable: Any] = [
                  "network-caching": 1000                    // Network resource caching in milliseconds.
                , "http-reconnect": ""                       // Auto-reconnect on sudden stream drop. Default disabled; critical for live IPTV streams with unstable connections.
                , "no-lua": ""                               // Disable all lua plugins. Boolean flags use empty string, not true/false.
                , "avcodec-hw": "none"                       // Disable avcodec's hardware acceleration. Does NOT disable VLC's separate videotoolbox decoder module (see forceSoftwareDecode).
//               , "avcodec-hw": "any"                        // Prefer hardware decode when possible (VideoToolbox on Apple). Reduces CPU load.
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
//                , "no-cc-opaque": ""
//                , "captions": 708
//                , "preferred-resolution": 1080
//                , "avcodec-debug": 1                         // FFmpeg debug mask: 1 = Detailed picture info, 2 = Rate Control details, 4 = Raw bit stream details. [https://www.ffmpeg.org/doxygen/0.6/avcodec_8h.html]
            ]

            if forceSoftwareDecode {
                // Put avcodec first in the decoder priority list so VLC's videotoolbox module is not used.
                // At ad discontinuities VideoToolbox was failing to create a decoder (VT-DS err -12906) and playback stalled.
                options["codec"] = "avcodec,all"
            }

            media.addOptions(options)
            return media
        }

        /// Rebuilds the media for the current stream and restarts playback, as if the user had switched away and back.
        /// Used to recover from a mid-stream stall such as a decoder failure at an HLS ad-break discontinuity.
        private func reloadCurrentStream() {
            guard let url = currentStreamURL else { return }

            stallRecoveryCount += 1
            lastStallRecoveryDate = Date()
            isReloadingStream = true
            lastPlaybackTime = nil
            resetAudioTrackState()
            logWarning("VLC: Playback stalled mid-stream (likely ad discontinuity) - reloading attempt \(stallRecoveryCount) of \(maxStallRecoveries)")

            mediaPlayer.stop()
            mediaPlayer.media = makeMedia(url: url)
            mediaPlayer.play()
        }

        private func pause() {
            guard mediaPlayer.canPause, mediaPlayer.isPlaying else { return }
            mediaPlayer.pause()
        }
        
        fileprivate func stop() {
            logDebug("VLC: Stop requested")
            isReloadingStream = false
            trackAvailabilityTask?.cancel()
            trackAvailabilityTask = nil
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

        //MARK: - Update Audio and Subtitle tracks.
        
        fileprivate func updateClosedCaptions() {
            guard mediaPlayer.currentVideoSubTitleIndex != appState.selectedSubtitleTrackIndex else {
                return
            }
            logDebug("VLC: Switching to subtitle track (index: \(appState.selectedSubtitleTrackIndex))")
            mediaPlayer.currentVideoSubTitleIndex = Int32(appState.selectedSubtitleTrackIndex)
        }

        // Dev Note: - Audio track bug (fixed)
        // VLC audio track "indexes" are elementary stream (ES) ids, not 0...n positions, and they belong to the
        // media instance that created them. Two problems caused audio to switch tracks or go silent:
        //   1) Stale ids: on a channel change or stall-recovery reload, appState.selectedAudioTrackIndex still held an
        //      ES id from the previous media. updateView() applied it to the new media, selecting the wrong track
        //      (e.g. the Audio-Description rendition) or a track that does not exist.
        //   2) Late audio: streams with a separate HLS audio rendition (e.g. PlutoTV) expose their audio ES a few
        //      seconds after .playing. The single 1.5s lookup found 0 tracks, set the selection to -1, and
        //      updateAudioTrack() then applied -1 - which is VLC's "Disable" track - turning the audio off.
        // Fix: reset the track state whenever new media is loaded, poll until audio tracks appear, default the
        // selection to the track VLC already chose, and never apply a selection that is not a valid track of the
        // current media (so -1 or a stale id can no longer disable or misselect audio).
        fileprivate func updateAudioTrack() {
            let selectedTrack = appState.selectedAudioTrackIndex
            guard mediaPlayer.currentAudioTrackIndex != selectedTrack else {
                return
            }
            // Only apply a real track that belongs to the current media; leave VLC's own choice alone otherwise.
            guard selectedTrack >= 0, validAudioTrackIds().contains(selectedTrack) else {
                return
            }
            logDebug("VLC: Switching to audio track index: \(selectedTrack)")
            mediaPlayer.currentAudioTrackIndex = Int32(selectedTrack)
        }

        /// Audio track (ES) ids available on the current media, excluding VLC's "Disable" track (-1).
        private func validAudioTrackIds() -> [Int] {
            let audioTrackIndexes = mediaPlayer.audioTrackIndexes.compactMap { $0 as? Int }
            return audioTrackIndexes.filter { $0 >= 0 }
        }

        /// Clears audio track state tied to the previous media. Call whenever new media is loaded.
        private func resetAudioTrackState() {
            trackAvailabilityTask?.cancel()
            trackAvailabilityTask = nil
            // Deferred: this can be called from updateView(), where shared state must not be mutated synchronously.
            // Until it runs, updateAudioTrack() ignores the stale id because it is not a track of the new media.
            Task { @MainActor in
                self.appState.availableAudioTracks = []
                self.appState.selectedAudioTrackIndex = -1
            }
        }

        //MARK: - Update available audio and subtitle tracks after waiting for the stream to settle.

        private func delayedAudioAndSubtitleAvailabilityUpdate() {
            trackAvailabilityTask?.cancel()
            trackAvailabilityTask = Task { @MainActor [weak self] in
                // Wait for VLC to initialize the stream. Streams with a separate audio rendition can take a few
                // seconds to expose their audio, so poll (1.5s apart) until audio tracks appear or attempts run out.
                for attempt in 1...(self?.maxTrackAvailabilityAttempts ?? 1) {
                    try? await Task.sleep(for: .seconds(1.5))
                    guard let self, !Task.isCancelled else { return }
                    if !self.validAudioTrackIds().isEmpty || attempt == self.maxTrackAvailabilityAttempts {
                        break
                    }
                }

                guard let self, !Task.isCancelled else { return }

                // Populate available subtitle and audio tracks
                self.updateAvailableSubtitleTracks()
                self.updateAvailableAudioTracks()

                // Update mediaPlayer to match the user selected state.
                self.updateClosedCaptions()
                self.updateAudioTrack()
            }
        }
        
        private func updateAvailableSubtitleTracks() {

            appState.selectedSubtitleTrackIndex = -1
            
            // Get available subtitle tracks from VLC
            let subtitleIndexes = mediaPlayer.videoSubTitlesIndexes.compactMap { $0 as? Int }
            
            let validTracks = subtitleIndexes
                .enumerated()
                .map { (index, subtitleIndex) in
                    let name: String = mediaPlayer.videoSubTitlesNames.indices.contains(index) ? mediaPlayer.videoSubTitlesNames[index] as! String : "Subtitle \(subtitleIndex)"
                    let item = TrackItem(id: index,
                                         index: subtitleIndex,
                                         name: name)
                    return item
                }
                .filter { $0.index >= 0 }  // Filter out the "Disable" track (index -1) if present
            
            // EJH: - Override - Just offer the first subtitle track.
            appState.availableSubtitleTracks = validTracks.first.map { [$0] } ?? []  //validTracks
            let tracks: NSString = validTracks.map { "Name: \($0.name)    Index: \($0.index)" }.joined(separator: "\n") as NSString
            let messageText: NSString = "VLC: Found subtitle tracks: \n\(tracks)" as NSString
            logDebug(messageText)
        }
        
        private func updateAvailableAudioTracks() {
            // Get available audio tracks from VLC
            // Note: -1 for the selection means "no selection - leave VLC's choice", never "disable audio" (see updateAudioTrack()).
            guard let audioTrackIndexes = mediaPlayer.audioTrackIndexes as? [Int],
                  let audioTrackNames = mediaPlayer.audioTrackNames as? [String] else {
                logDebug("VLC: No audio tracks available")
                appState.availableAudioTracks = []
                appState.selectedAudioTrackIndex = -1
                return
            }

            // Filter out the "Disable" track (index -1) if present
            let validTracks = zip(audioTrackIndexes, audioTrackNames)
                .filter { $0.0 >= 0 }
                .map {
                    TrackItem(id: $0.0,
                              index: $0.0,
                              name: $0.1)
                }

            appState.availableAudioTracks = validTracks

            // Default to the track VLC is already playing (respects its language defaults) rather than forcing the first one.
            let currentTrack = Int(mediaPlayer.currentAudioTrackIndex)
            if validTracks.contains(where: { $0.index == currentTrack }) {
                appState.selectedAudioTrackIndex = currentTrack
            } else {
                appState.selectedAudioTrackIndex = validTracks.first?.index ?? -1
            }

            logDebug("VLC: Detected \(validTracks.count) audio tracks (selected: \(appState.selectedAudioTrackIndex))")
        }
        
        // MARK: - Playback Monitoring

        // Dev Note: - VLC playback watchdog (stall recovery / unplayable)
        // Why: VLC 3 (TVVLCKit/MobileVLCKit 3.0.x) can freeze mid-stream without reporting an error. Seen with PlutoTV
        // HLS (separate video/audio/WebVTT renditions): at an ad-break #EXT-X-DISCONTINUITY the adaptive demuxer
        // restarts ("Ending demuxer stream. [discontinuity]") and its playback time freezes, even though segments keep
        // downloading. VLC stays in .buffering/.playing, so the only reliable signal is "playback time stopped moving".
        // (IPTV channels normally play in AVPlayer - see UnifiedPlayerView - so this mostly matters for HDHomeRun and
        // for IPTV streams that fell back to VLC.)
        //
        // How:
        //   1) Monitoring (re)starts on .opening and on resume. The Watchdog calls the closure below once per second.
        //   2) Progress = mediaPlayerTimeChanged with a *different* mediaPlayer.time. VLC keeps firing time-changed
        //      events while frozen, so the event alone is not progress. lastTimeUpdate records the last real progress.
        //   3) Thresholds: startupStallThreshold (7s) until the first real progress (opening, reload, resume), then
        //      midStreamStallThreshold (3s). lastPlaybackTime == nil is what marks "startup".
        //   4) Stall after the stream has played (.playing reached) -> reloadCurrentStream(): stop, fresh VLCMedia,
        //      play - the same thing a manual channel switch away and back does. isReloadingStream keeps the transient
        //      .stopped event from shutting the watchdog down. Up to maxStallRecoveries (3) reloads; the count resets
        //      after stallRecoveryResetInterval (20s) of real progress, so every ad break gets a fresh budget.
        //   5) Stall before the stream ever played, or reloads exhausted -> isStreamUnplayable = true. VLCPlayerView shows
        //      UnplayableStreamOverlay and updateView() stops the player. Selecting another channel clears the flag.
        // Separately, VLC's own .error state is retried up to maxErrorRetries in mediaPlayerStateChanged(_:).

        private let playerWatchdog = Watchdog()
        
        private func startPlaybackMonitoring() {
            self.lastTimeUpdate = Date()
            // Opening, reloading and resuming are all startup: use the startup threshold until playback progresses again.
            self.lastPlaybackTime = nil
            Task { [weak self] in
                guard let self else { return }
                await self.playerWatchdog.start { @MainActor [weak self] in
                    
                    guard let self, let lastUpdate = self.lastTimeUpdate else {
                        //Invalid state - stop watchdog.
                        return false
                    }
                    
                    // Check if we've received any time updates
                    
                    let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)

                    // Once playback has actually progressed, use the short mid-stream threshold so frozen streams
                    // (e.g. at ad-break discontinuities) recover quickly. Until then allow the longer startup time.
                    let threshold = self.lastPlaybackTime == nil ? self.startupStallThreshold : self.midStreamStallThreshold

                    if timeSinceUpdate > threshold && self.appState.isPlayerPaused == false {

                        // Stream was playing and then stalled (e.g. VLC stuck buffering at an ad-break discontinuity).
                        // Try reloading it before giving up - this is what a manual channel switch away and back does.
                        if self.hasReachedPlaying && self.stallRecoveryCount < self.maxStallRecoveries {
                            logWarning("VLC: No playback progress for \(String(format: "%.1f", timeSinceUpdate))s (threshold \(threshold)s) - player state: \(self.mediaPlayer.state.rawValue), isPlaying: \(self.mediaPlayer.isPlaying)")
                            self.reloadCurrentStream()
                            self.lastTimeUpdate = Date()
                            return true
                        }

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
                logDebug("VLC: Media URL: \(player.media?.url?.absoluteString ?? "unknown")")
                Task { @MainActor in
                    self.isSwitchingStreams = true
                    self.startPlaybackMonitoring()
                }
                
            case .esAdded:
                // Elementary Stream added
                logDebug("VLC State: Elementary Stream Added")

            case .buffering:
                // logDebug("VLC State: Buffering")
                Task { @MainActor in
                    self.lastTimeUpdate = Date()
                }
                
            case .playing:
                logDebug("VLC State: Playing")
                Task { @MainActor in
                    // Playback started successfully, reset flags
                    self.errorRetryCount = 0
                    self.hasReachedPlaying = true
                    self.isReloadingStream = false
                    self.isSwitchingStreams = false
                    self.isStreamUnplayable = false
                    // After a delay, resets the available audio and subtitle tracks found in the stream.
                    self.delayedAudioAndSubtitleAvailabilityUpdate()
                }
                
            case .paused:
                logDebug("VLC State: Paused")
                Task { @MainActor in
                    self.stopPlaybackMonitoring()
                }

            case .stopped:
                logDebug("VLC State: Stopped")
                Task { @MainActor in
                    // During a stall-recovery reload the stop is transient - keep the watchdog on patrol.
                    guard not(self.isReloadingStream) else { return }
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
                        player.stop()
                        try? await Task.sleep(for: .seconds(0.5))
                        player.play()
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
            // VLC keeps firing time-changed events even when playback is frozen (e.g. demux stuck after an
            // ad-break discontinuity), so only count it as progress when the playback time actually advances.
            let playbackTime = self.mediaPlayer.time.intValue
            guard playbackTime != self.lastPlaybackTime else { return }
            self.lastPlaybackTime = playbackTime

            // Update last time we saw playback progressing
            self.lastTimeUpdate = Date()

            // After a period of healthy playback following a stall recovery, restore the full recovery budget for the next ad break.
            if self.stallRecoveryCount > 0,
               let lastRecovery = self.lastStallRecoveryDate,
               Date().timeIntervalSince(lastRecovery) > self.stallRecoveryResetInterval {
                logDebug("VLC: Playback healthy since last stall recovery - resetting recovery count")
                self.stallRecoveryCount = 0
                self.lastStallRecoveryDate = nil
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
