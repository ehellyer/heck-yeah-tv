//
//  AVPlayerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/26/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import AVFoundation

/// Plays an IPTV (HLS) channel with AVPlayer.
///
/// AVPlayer handles HLS ad insertion (discontinuities, separate audio/subtitle renditions) far better than VLC 3,
/// but some IPTV streams fail or stall in AVPlayer. When that happens `onPlaybackFailure` is called with the stream
/// URL so the parent (`UnifiedPlayerView`) can fall back to VLC for that stream.
struct AVPlayerView: View {

    let channel: Channel

    /// Called once when AVPlayer cannot play the stream (failed to load, did not start, or stalled).
    let onPlaybackFailure: (URL) -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var controller = AVPlaybackController()

    var body: some View {
        ZStack {
            AVPlayerLayerRepresentable(controller: controller)

            if controller.isLoading {
                StreamSwitchingActivity()
            }
        }
        .trackScreen("Player")
        .onAppear {
            controller.onPlaybackFailure = onPlaybackFailure
            controller.setVolume(appState.playerVolume)
            loadChannel(url: channel.url)
        }
        .onDisappear {
            controller.stop()
        }
        .onChange(of: channel.url) { _, newURL in
            loadChannel(url: newURL)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                // Live stream: reload to rejoin at the live edge when returning to the foreground.
                loadChannel(url: channel.url)
            } else {
                controller.stop()
            }
        }
        .onChange(of: appState.isPlayerPaused) { _, isPaused in
            controller.setPaused(isPaused)
        }
        .onChange(of: appState.playerVolume) { _, volume in
            controller.setVolume(volume)
        }
        .onChange(of: appState.selectedAudioTrackIndex) { _, index in
            controller.selectAudioTrack(index: index)
        }
        .onChange(of: appState.selectedSubtitleTrackIndex) { _, index in
            controller.selectSubtitleTrack(index: index)
        }
    }

    private func loadChannel(url: URL) {
        logDebug("AVPlayer: Loading IPTV channel '\(channel.title)' from \(url.absoluteString)")

        // Clear tracks left over from the previous stream (VLC or AVPlayer). The controller repopulates
        // them from the new stream's HLS media selection groups once they load.
        appState.availableAudioTracks = []
        appState.selectedAudioTrackIndex = -1
        appState.availableSubtitleTracks = []
        appState.selectedSubtitleTrackIndex = -1

        controller.load(url: url, shouldPlay: !appState.isPlayerPaused)
    }
}

//MARK: - AVPlaybackController

/// Owns the AVPlayer and watches it for failures and stalls.
///
/// Dev Note: - AVPlayer watchdog (fallback to VLC)
/// AVPlayer rarely reports failure for live streams it can't really play - it may sit waiting forever, stall, or
/// play audio with no video. So a Watchdog polls checkPlayback() once per second (polling avoids KVO and keeps
/// everything on the main actor). It gives up on AVPlayer and calls onPlaybackFailure (once per load) when:
///   - the AVPlayerItem status becomes .failed;
///   - playback has not started within startupTimeout (10s);
///   - after starting, playback time stops moving for stallTimeout (6s). AVPlayer re-buffers short network hiccups
///     itself, so this only trips on real stalls;
///   - audio plays but no video frame is ever displayed within videoStartTimeout (5s) of playback starting, while the
///     stream has a video track (AVPlayerLayer.isReadyForDisplay never becomes true - e.g. VT-DS err -8969).
/// AVPlayer never shows the unplayable overlay itself; UnifiedPlayerView switches the stream to VLC, and VLC's
/// watchdog decides whether the stream is truly unplayable.
@MainActor
@Observable
final class AVPlaybackController {

    let player = AVPlayer()

    /// True while the stream is starting up or AVPlayer is waiting for data.
    private(set) var isLoading = false

    @ObservationIgnored var onPlaybackFailure: ((URL) -> Void)?

    /// The layer rendering `player`; used to confirm video frames are actually displayed.
    @ObservationIgnored weak var playerLayer: AVPlayerLayer?

    //MARK: - Private API

    // Seconds allowed for the stream to start playing before giving up on AVPlayer.
    @ObservationIgnored private let startupTimeout: TimeInterval = 10
    // Seconds without playback progress, after playback started, before giving up on AVPlayer.
    @ObservationIgnored private let stallTimeout: TimeInterval = 6
    // Seconds after playback starts for the first video frame to be displayed, when the stream has video.
    @ObservationIgnored private let videoStartTimeout: TimeInterval = 5

    @ObservationIgnored private let watchdog = Watchdog()
    @ObservationIgnored private var currentURL: URL?
    @ObservationIgnored private var shouldPlay = true
    @ObservationIgnored private var hasStartedPlaying = false
    @ObservationIgnored private var hasReportedFailure = false
    @ObservationIgnored private var lastPlaybackTime: CMTime?
    @ObservationIgnored private var lastProgressDate = Date()
    @ObservationIgnored private var playbackStartDate: Date?
    @ObservationIgnored private var hasVerifiedVideo = false

    // HLS media selection (audio renditions and subtitles/captions) for the current item.
    // The app's TrackItem.index for AVPlayer tracks is the option's position in these arrays.
    @ObservationIgnored private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @ObservationIgnored private var audibleGroup: AVMediaSelectionGroup?
    @ObservationIgnored private var legibleGroup: AVMediaSelectionGroup?
    @ObservationIgnored private var audioOptions: [AVMediaSelectionOption] = []
    @ObservationIgnored private var subtitleOptions: [AVMediaSelectionOption] = []

    //MARK: - Player controls

    func load(url: URL, shouldPlay: Bool) {
        currentURL = url
        self.shouldPlay = shouldPlay
        hasStartedPlaying = false
        hasReportedFailure = false
        lastPlaybackTime = nil
        lastProgressDate = Date()
        playbackStartDate = nil
        hasVerifiedVideo = false

        let assetOptions: [String: Any] = [
            AVURLAssetAllowsConstrainedNetworkAccessKey: true,
            AVURLAssetAllowsExpensiveNetworkAccessKey: true
        ]
        let asset = AVURLAsset(url: url, options: assetOptions)
        let item = AVPlayerItem(asset: asset)
        player.replaceCurrentItem(with: item)
        isLoading = shouldPlay
        clearMediaSelection()

        guard not(PreviewDetector.isRunningInPreview) else { return }

        if shouldPlay {
            player.play()
        }
        startMonitoring()
        loadMediaSelection(asset: asset, item: item)
    }

    func setPaused(_ isPaused: Bool) {
        shouldPlay = !isPaused
        if isPaused {
            player.pause()
        } else {
            lastProgressDate = Date()
            player.play()
        }
    }

    func setVolume(_ volume: Int32) {
        // App volume uses VLC's 0-200 scale (100 = normal). AVPlayer volume is 0.0-1.0 and cannot amplify.
        player.volume = Float(min(max(volume, 0), 100)) / 100
    }

    func stop() {
        stopMonitoring()
        player.pause()
        player.replaceCurrentItem(with: nil)
        currentURL = nil
        isLoading = false
        clearMediaSelection()
    }

    //MARK: - Audio and subtitle tracks

    /// Selects an audio rendition by its index in `audioOptions` (the TrackItem.index published to appState).
    func selectAudioTrack(index: Int) {
        guard let item = player.currentItem, let group = audibleGroup, audioOptions.indices.contains(index) else { return }
        let option = audioOptions[index]
        guard item.currentMediaSelection.selectedMediaOption(in: group) != option else { return }
        logDebug("AVPlayer: Switching to audio track '\(option.displayName)'")
        item.select(option, in: group)
    }

    /// Selects a subtitle/caption option by its index in `subtitleOptions`, or turns subtitles off for -1.
    func selectSubtitleTrack(index: Int) {
        guard let item = player.currentItem, let group = legibleGroup else { return }
        let option: AVMediaSelectionOption? = subtitleOptions.indices.contains(index) ? subtitleOptions[index] : nil
        guard item.currentMediaSelection.selectedMediaOption(in: group) != option else { return }
        logDebug("AVPlayer: Switching subtitles to '\(option?.displayName ?? "Off")'")
        item.select(option, in: group)
    }

    private func clearMediaSelection() {
        audibleGroup = nil
        legibleGroup = nil
        audioOptions = []
        subtitleOptions = []
    }

    /// Loads the stream's audio and subtitle options (from the HLS master playlist) and publishes them to
    /// appState so the player overlay's audio track and closed caption menus appear for AVPlayer streams.
    private func loadMediaSelection(asset: AVURLAsset, item: AVPlayerItem) {
        Task { [weak self] in
            let audible = try? await asset.loadMediaSelectionGroup(for: .audible)
            let legible = try? await asset.loadMediaSelectionGroup(for: .legible)

            // Ignore results for an item that has since been replaced (channel change, reload, stop).
            guard let self, self.player.currentItem === item else { return }

            self.audibleGroup = audible
            self.legibleGroup = legible
            self.audioOptions = audible?.options ?? []
            // Forced-only subtitles are shown automatically by AVPlayer when needed; they are not user choices.
            self.subtitleOptions = (legible?.options ?? []).filter {
                not($0.hasMediaCharacteristic(.containsOnlyForcedSubtitles))
            }

            self.appState.availableAudioTracks = self.audioOptions.enumerated().map { index, option in
                TrackItem(id: index, index: index, name: option.displayName)
            }
            self.appState.availableSubtitleTracks = self.subtitleOptions.enumerated().map { index, option in
                TrackItem(id: index, index: index, name: option.displayName)
            }

            // Reflect what AVPlayer selected by default so the menus show the right checkmarks.
            let selection = item.currentMediaSelection
            let selectedAudio = audible.flatMap { selection.selectedMediaOption(in: $0) }
            let selectedSubtitle = legible.flatMap { selection.selectedMediaOption(in: $0) }
            self.appState.selectedAudioTrackIndex = selectedAudio.flatMap { self.audioOptions.firstIndex(of: $0) } ?? (self.audioOptions.isEmpty ? -1 : 0)
            self.appState.selectedSubtitleTrackIndex = selectedSubtitle.flatMap { self.subtitleOptions.firstIndex(of: $0) } ?? -1

            logDebug("AVPlayer: Detected \(self.audioOptions.count) audio tracks and \(self.subtitleOptions.count) subtitle tracks (selected audio: \(self.appState.selectedAudioTrackIndex), subtitles: \(self.appState.selectedSubtitleTrackIndex))")
        }
    }

    //MARK: - Playback monitoring

    private func startMonitoring() {
        // Watchdog.start replaces any monitoring already running.
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

    /// Watchdog patrol. Returns false to stop monitoring.
    private func checkPlayback() -> Bool {
        guard let item = player.currentItem, let url = currentURL else { return false }

        if item.status == .failed {
            reportFailure(url: url, reason: "item failed - \(item.error?.localizedDescription ?? "unknown error")")
            return false
        }

        // Paused by the user - nothing to check.
        guard shouldPlay else {
            lastProgressDate = Date()
            isLoading = false
            return true
        }

        // Progress = AVPlayer is playing and its playback time has moved.
        let currentTime = player.currentTime()
        if player.timeControlStatus == .playing, currentTime != lastPlaybackTime {
            lastPlaybackTime = currentTime
            lastProgressDate = Date()
            if not(hasStartedPlaying) {
                hasStartedPlaying = true
                playbackStartDate = Date()
                logDebug("AVPlayer: Playback started for \(url.absoluteString)")
            }
            isLoading = false
            return checkVideoRendering(item: item, url: url)
        }

        let timeout = hasStartedPlaying ? stallTimeout : startupTimeout
        let timeSinceProgress = Date().timeIntervalSince(lastProgressDate)
        if timeSinceProgress > timeout {
            let reason = hasStartedPlaying
                ? "stalled - no playback progress for \(String(format: "%.1f", timeSinceProgress))s"
                : "did not start within \(Int(startupTimeout))s"
            reportFailure(url: url, reason: reason)
            return false
        }

        // Show the activity indicator while AVPlayer is starting or re-buffering.
        isLoading = true
        return true
    }

    /// Audio can play - and the playback clock advance - while video fails to decode (e.g. VideoToolbox
    /// rejecting the stream, VT-DS err -8969). Once playback starts, confirm a video frame is actually displayed.
    /// Returns false (stop monitoring) if video never appears.
    private func checkVideoRendering(item: AVPlayerItem, url: URL) -> Bool {
        guard not(hasVerifiedVideo), let startDate = playbackStartDate else { return true }

        if playerLayer?.isReadyForDisplay == true {
            hasVerifiedVideo = true
            logDebug("AVPlayer: Video rendering confirmed for \(url.absoluteString)")
            return true
        }

        guard Date().timeIntervalSince(startDate) > videoStartTimeout else { return true }

        let hasVideoTrack = item.presentationSize != .zero
            || item.tracks.contains { $0.assetTrack?.mediaType == .video }
        if hasVideoTrack {
            reportFailure(url: url, reason: "audio playing but no video frame displayed within \(Int(videoStartTimeout))s")
            return false
        }

        // Audio-only stream - nothing to verify.
        hasVerifiedVideo = true
        return true
    }

    private func reportFailure(url: URL, reason: String) {
        guard not(hasReportedFailure) else { return }
        hasReportedFailure = true
        logError("AVPlayer: Unable to play \(url.absoluteString) (\(reason)) - falling back to VLC")
        player.pause()
        isLoading = false
        onPlaybackFailure?(url)
    }
}

//MARK: - AVPlayerLayer view

/// Renders an AVPlayer into a plain layer-backed view.
/// Used instead of SwiftUI's VideoPlayer, which adds transport controls and takes focus/remote input on tvOS.
private struct AVPlayerLayerRepresentable: CrossPlatformRepresentable {

    let controller: AVPlaybackController

    func makeView(context: Context) -> PlatformView {
        let view = PlayerLayerView()
        view.playerLayer.player = controller.player
        controller.playerLayer = view.playerLayer
        return view
    }

    func updateView(_ view: PlatformView, context: Context) {
        guard let playerView = view as? PlayerLayerView, playerView.playerLayer.player !== controller.player else { return }
        playerView.playerLayer.player = controller.player
        controller.playerLayer = playerView.playerLayer
    }
}

private final class PlayerLayerView: PlatformView {

    let playerLayer = AVPlayerLayer()

    init() {
        super.init(frame: .zero)
        playerLayer.videoGravity = .resizeAspect
#if os(macOS)
        wantsLayer = true
        layer?.backgroundColor = PlatformColor.clear.cgColor
        layer?.addSublayer(playerLayer)
#else
        isUserInteractionEnabled = false
        backgroundColor = PlatformColor.clear
        layer.addSublayer(playerLayer)
#endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

#if os(macOS)
    override func layout() {
        super.layout()
        updatePlayerLayerFrame()
    }
#else
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePlayerLayerFrame()
    }
#endif

    private func updatePlayerLayerFrame() {
        // Disable implicit animation so the video does not animate when the view resizes.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}
