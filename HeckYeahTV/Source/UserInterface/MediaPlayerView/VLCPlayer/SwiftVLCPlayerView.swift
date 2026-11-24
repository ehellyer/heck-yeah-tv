//
//  SwiftVLCPlayerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/24/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftVLC

// Dev Note: - SwiftVLC (libVLC 4)
// Replaced VLCKit 3 (TVVLCKit/MobileVLCKit via CocoaPods). libVLC 4 rewrote HLS adaptive streaming / discontinuity
// handling; VLC 3 froze at ad-break discontinuities (see Docs/MediaPlayback.md). Contract with VLCPlayerView:
// selected channel, pause intent, scene phase, volume, and the isStreamUnplayable / isSwitchingStreams flags.
//
// Dev Note: - VLC playback watchdog (stall recovery / unplayable)
// Why: libVLC can stall without reporting an error (VLC 3 did this at PlutoTV ad breaks while still in
// .buffering/.playing), so the reliable signal is "playback time stopped moving".
// How:
//   1) Monitoring (re)starts on load, reload and resume. The Watchdog calls checkPlayback() once per second.
//   2) Progress = .playing and a *different* player.currentTime.
//   3) Thresholds: startupStallThreshold (7s) until the first real progress, then midStreamStallThreshold (3s).
//      lastPlaybackTime == nil is what marks "startup".
//   4) Stall after the stream has reached .playing -> reloadCurrentStream() with fresh media, the same thing a manual
//      channel switch away and back does. Up to maxStallRecoveries (3) reloads; the count resets after
//      stallRecoveryResetInterval (20s) of real progress.
//   5) Stall before the stream ever played, or reloads exhausted -> isStreamUnplayable. VLCPlayerView shows
//      UnplayableStreamOverlay and the player stops. Selecting another channel clears the flag.
// Separately, libVLC's own error state is retried up to maxErrorRetries in handleError().

/// VLC player view backed by SwiftVLC (libVLC 4).
struct SwiftVLCPlayerView: View {

    let selectedChannel: Channel?
    let shouldPause: Bool
    let scenePhase: ScenePhase
    let playerVolume: Int32
    @Binding var isStreamUnplayable: Bool
    @Binding var isSwitchingStreams: Bool

    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var controller = SwiftVLCPlaybackController()

    var body: some View {
        VideoView(controller.player)
            .onAppear {
                controller.setVolume(playerVolume)
                reconcile()
            }
            .onDisappear {
                controller.stop()
            }
            .onChange(of: selectedChannel?.url) { reconcile() }
            .onChange(of: shouldPause) { reconcile() }
            .onChange(of: scenePhase) { reconcile() }
            .onChange(of: isStreamUnplayable) { reconcile() }
            .onChange(of: playerVolume) { _, volume in
                controller.setVolume(volume)
            }
            .onChange(of: appState.selectedAudioTrackIndex) { _, index in
                controller.selectAudioTrack(index: index)
            }
            .onChange(of: appState.selectedSubtitleTrackIndex) { _, index in
                controller.selectSubtitleTrack(index: index)
            }
            // Publish the controller's status to VLCPlayerView's overlay flags.
            .onChange(of: controller.isStreamUnplayable) { _, isUnplayable in
                isStreamUnplayable = isUnplayable
            }
            .onChange(of: controller.isSwitchingStreams) { _, isSwitching in
                isSwitchingStreams = isSwitching
            }
    }

    /// Pushes the current channel, pause intent and scene phase to the controller.
    private func reconcile() {
        controller.update(url: selectedChannel?.url,
                          shouldPause: shouldPause,
                          isSceneActive: scenePhase == .active,
                          isMarkedUnplayable: isStreamUnplayable)
    }
}

//MARK: - SwiftVLCPlaybackController

/// Owns the SwiftVLC Player, loads channels, publishes tracks, and runs the stall watchdog.
@MainActor
@Observable
final class SwiftVLCPlaybackController {

    let player = Player()

    /// Mirrored into VLCPlayerView's bindings.
    private(set) var isStreamUnplayable = false
    private(set) var isSwitchingStreams = false

    init() {
        startEventLoop()
        Self.startLibVLCLoggingIfNeeded()
    }

    //MARK: - Private API

    @ObservationIgnored private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @ObservationIgnored private let watchdog = Watchdog()
    @ObservationIgnored private var eventTask: Task<Void, Never>?

    @ObservationIgnored private var currentURL: URL?
    @ObservationIgnored private var hasActiveMedia = false
    @ObservationIgnored private var shouldPause = false

    // Error retries (libVLC error state).
    @ObservationIgnored private var errorRetryCount = 0
    @ObservationIgnored private let maxErrorRetries = 3
    @ObservationIgnored private var lastErrorDate: Date?

    // Stall recovery - see the "VLC playback watchdog" Dev Note at the top of this file.
    @ObservationIgnored private var hasReachedPlaying = false
    @ObservationIgnored private var stallRecoveryCount = 0
    @ObservationIgnored private let maxStallRecoveries = 3
    @ObservationIgnored private var lastStallRecoveryDate: Date?
    @ObservationIgnored private let stallRecoveryResetInterval: TimeInterval = 20
    @ObservationIgnored private let startupStallThreshold: TimeInterval = 7
    @ObservationIgnored private let midStreamStallThreshold: TimeInterval = 3
    // nil until playback has actually progressed; marks "startup" for the threshold.
    @ObservationIgnored private var lastPlaybackTime: Duration?
    @ObservationIgnored private var lastProgressDate = Date()

    //MARK: - Player controls

    /// Reconciles the selected channel and play/pause intent with the player state.
    func update(url: URL?, shouldPause: Bool, isSceneActive: Bool, isMarkedUnplayable: Bool) {
        self.shouldPause = shouldPause

        // Very coarse: if the app is not active, stop.
        guard isSceneActive, let url else {
            stop()
            return
        }

        // Stream marked unplayable for this channel - stay stopped until the channel changes or the flag is cleared.
        if url == currentURL && isMarkedUnplayable {
            stopPlayback()
            return
        }

        // New channel, or a retry after stop / background / unplayable.
        if url != currentURL || not(hasActiveMedia) {
            load(url: url)
            return
        }

        // Same channel: reconcile pause intent.
        if shouldPause {
            if player.state.isPlaying || player.state.isBuffering {
                logDebug("SwiftVLC: Pausing playback")
                player.pause()
            }
        } else if player.state.isPaused {
            logDebug("SwiftVLC: Resuming playback")
            player.resume()
            startMonitoring()
        }
    }

    func stop() {
        stopPlayback()
    }

    func setVolume(_ volume: Int32) {
        // App volume uses VLC's 0-200 scale (100 = normal); SwiftVLC's Volume is 0.0-2.0.
        let clamped = Float(min(max(volume, 0), 200)) / 100
        try? player.setAudioVolume(Volume(clamped))
    }

    private func load(url: URL) {
        logDebug("SwiftVLC: Loading channel URL: \(url.absoluteString)")
        currentURL = url
        hasActiveMedia = true
        errorRetryCount = 0
        hasReachedPlaying = false
        stallRecoveryCount = 0
        lastStallRecoveryDate = nil
        isStreamUnplayable = false
        isSwitchingStreams = true
        resetTracks()

        guard not(PreviewDetector.isRunningInPreview) else { return }

        do {
            let media = try makeMedia(url: url)
            if shouldPause {
                logDebug("SwiftVLC: Media loaded but paused by user")
                player.load(media)
                isSwitchingStreams = false
            } else {
                try player.play(media)
                startMonitoring()
            }
        } catch {
            logError("SwiftVLC: Unable to start \(url.absoluteString) - \(error)")
            markUnplayable()
        }
    }

    /// Stops playback but keeps currentURL, so the unplayable state stays tied to the channel.
    private func stopPlayback() {
        guard hasActiveMedia else { return }
        logDebug("SwiftVLC: Stop requested")
        hasActiveMedia = false
        stopMonitoring()
        player.stop()
        isSwitchingStreams = false
    }

    /// Builds media for a live stream. libVLC 4 uses its defaults except for the options below; the old VLC 3
    /// tuning options were intentionally not carried over until a need is shown.
    private func makeMedia(url: URL) throws(VLCError) -> Media {
        let media = try Media(url: url)
        media.addOption(":network-caching=1000")   // Network buffer in milliseconds.
        media.addOption(":http-reconnect")          // Auto-reconnect on a dropped HTTP connection.
        return media
    }

    /// Fresh media for the same URL - what a manual channel switch away and back does.
    private func reloadCurrentStream() {
        guard let url = currentURL else { return }
        stallRecoveryCount += 1
        lastStallRecoveryDate = Date()
        lastPlaybackTime = nil
        lastProgressDate = Date()
        resetTracks()
        logWarning("SwiftVLC: Playback stalled mid-stream (likely ad discontinuity) - reloading attempt \(stallRecoveryCount) of \(maxStallRecoveries)")
        do {
            try player.play(try makeMedia(url: url))
        } catch {
            logError("SwiftVLC: Reload failed for \(url.absoluteString) - \(error)")
            markUnplayable()
        }
    }

    private func markUnplayable() {
        logError("SwiftVLC: Marking stream as unplayable: \(currentURL?.absoluteString ?? "unknown")")
        stopMonitoring()
        isStreamUnplayable = true
        isSwitchingStreams = false
    }

    //MARK: - Player events

    private func startEventLoop() {
        let events = player.events
        eventTask = Task { @MainActor [weak self] in
            for await event in events {
                guard let self else { return }
                self.handle(event)
            }
        }
    }

    private func handle(_ event: PlayerEvent) {
        switch event {
            case .stateChanged(let state):
                switch state {
                    case .opening:
                        logDebug("SwiftVLC State: Opening stream...")
                        isSwitchingStreams = true
                    case .playing:
                        logDebug("SwiftVLC State: Playing")
                        hasReachedPlaying = true
                        errorRetryCount = 0
                        isSwitchingStreams = false
                        isStreamUnplayable = false
                        publishTracks()
                    case .error:
                        handleError()
                    default:
                        break
                }
            case .tracksChanged:
                publishTracks()
            case .encounteredError:
                handleError()
            default:
                break
        }
    }

    private func handleError() {
        // libVLC may report one failure as both an error state and an error event - count it once.
        if let lastErrorDate, Date().timeIntervalSince(lastErrorDate) < 1 { return }
        lastErrorDate = Date()
        guard hasActiveMedia, let url = currentURL else { return }

        errorRetryCount += 1
        logError("SwiftVLC State: ERROR - \(url.absoluteString)")
        guard errorRetryCount <= maxErrorRetries else {
            logError("SwiftVLC: Max retry attempts (\(maxErrorRetries)) reached - stream is unplayable")
            markUnplayable()
            return
        }

        logError("SwiftVLC: Retry attempt \(errorRetryCount) of \(maxErrorRetries)")
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.5))
            guard let self, self.hasActiveMedia, self.currentURL == url else { return }
            do {
                try self.player.play(try self.makeMedia(url: url))
            } catch {
                self.markUnplayable()
            }
        }
    }

    //MARK: - Audio and subtitle tracks

    // TrackItem.index for SwiftVLC tracks is the track's position in player.audioTracks / offeredSubtitleTracks.
    // Lists are republished on every .tracksChanged, and selections are range-checked against the current lists,
    // so a stale index can never select the wrong track or disable audio.

    /// Only the first subtitle track is offered.
    private var offeredSubtitleTracks: [Track] {
        Array(player.subtitleTracks.prefix(1))
    }

    func selectAudioTrack(index: Int) {
        let tracks = player.audioTracks
        guard tracks.indices.contains(index), not(tracks[index].isSelected) else { return }
        logDebug("SwiftVLC: Switching to audio track '\(tracks[index].name)'")
        player.selectedAudioTrack = tracks[index]
    }

    func selectSubtitleTrack(index: Int) {
        let tracks = offeredSubtitleTracks
        let target: Track? = tracks.indices.contains(index) ? tracks[index] : nil
        guard player.selectedSubtitleTrack != target else { return }
        logDebug("SwiftVLC: Switching subtitles to '\(target?.name ?? "Off")'")
        player.selectedSubtitleTrack = target
    }

    private func resetTracks() {
        appState.availableAudioTracks = []
        appState.selectedAudioTrackIndex = -1
        appState.availableSubtitleTracks = []
        appState.selectedSubtitleTrackIndex = -1
    }

    private func publishTracks() {
        let audioTracks = player.audioTracks
        let subtitleTracks = offeredSubtitleTracks
        appState.availableAudioTracks = audioTracks.enumerated().map { index, track in
            TrackItem(id: index, index: index, name: track.name)
        }
        appState.availableSubtitleTracks = subtitleTracks.enumerated().map { index, track in
            TrackItem(id: index, index: index, name: track.name)
        }
        // -1 means "no selection" (leave libVLC's choice), never "disable audio".
        appState.selectedAudioTrackIndex = audioTracks.firstIndex(where: \.isSelected) ?? -1
        appState.selectedSubtitleTrackIndex = subtitleTracks.firstIndex(where: \.isSelected) ?? -1
    }

    //MARK: - Playback monitoring

    private func startMonitoring() {
        // Opening, reloading and resuming are all startup: use the startup threshold until playback progresses.
        lastPlaybackTime = nil
        lastProgressDate = Date()
        Task { [weak self] in
            guard let self else { return }
            await self.watchdog.start { @MainActor [weak self] in
                guard let self else { return false }
                return self.checkPlayback()
            }
        }
    }

    private func stopMonitoring() {
        Task {
            await watchdog.stop()
        }
    }

    /// Watchdog patrol, once per second. Returns false to stop monitoring.
    private func checkPlayback() -> Bool {
        guard hasActiveMedia else { return false }

        // Paused by the user - nothing to check.
        guard not(shouldPause) else {
            lastProgressDate = Date()
            return true
        }

        // Progress = playing and the playback time has actually moved.
        let time = player.currentTime
        if player.state.isPlaying, time != lastPlaybackTime {
            lastPlaybackTime = time
            lastProgressDate = Date()
            if stallRecoveryCount > 0,
               let lastRecovery = lastStallRecoveryDate,
               Date().timeIntervalSince(lastRecovery) > stallRecoveryResetInterval {
                logDebug("SwiftVLC: Playback healthy since last stall recovery - resetting recovery count")
                stallRecoveryCount = 0
                lastStallRecoveryDate = nil
            }
            return true
        }

        let threshold = lastPlaybackTime == nil ? startupStallThreshold : midStreamStallThreshold
        let timeSinceProgress = Date().timeIntervalSince(lastProgressDate)
        guard timeSinceProgress > threshold else { return true }

        logWarning("SwiftVLC: No playback progress for \(String(format: "%.1f", timeSinceProgress))s (threshold \(threshold)s) - player state: \(player.state)")
        if hasReachedPlaying && stallRecoveryCount < maxStallRecoveries {
            reloadCurrentStream()
            return true
        }
        markUnplayable()
        return false
    }

    //MARK: - libVLC logging

    private static var isLoggingStarted = false

    /// DEBUG only: forwards libVLC 4 log entries (errors) to the app log. Lower minimumLevel to diagnose stalls.
    private static func startLibVLCLoggingIfNeeded() {
#if DEBUG
        guard not(isLoggingStarted) else { return }
        isLoggingStarted = true
        let stream = VLCInstance.shared.logStream(minimumLevel: .error)
        Task {
            for await entry in stream {
                logDebug("libVLC [\(entry.module ?? "-")] \(entry.message)")
            }
        }
#endif
    }
}
