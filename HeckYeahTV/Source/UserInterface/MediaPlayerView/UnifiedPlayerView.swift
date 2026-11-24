//
//  UnifiedPlayerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/25/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI


/// Unified player view that automatically switches between VLC and AVPlayer based on channel type.
/// - IPTV channels (deviceId == IPTVImporter.iptvDeviceId) try AVPlayer first; it handles HLS ad-insertion
///   discontinuities natively (e.g. PlutoTV).
/// - If AVPlayer cannot play an IPTV stream (fails, never starts, or stalls), that stream falls back to VLC
///   for the rest of the session.
/// - HDHomeRun channels (deviceId != IPTVImporter.iptvDeviceId) always use VLC for MPEG-TS streams.
///
/// Dev Note: - Why two players
/// - HDHomeRun tuners serve raw MPEG-TS over HTTP. AVPlayer cannot play that (it only plays HLS/progressive
///   containers), so HDHomeRun is VLC-only.
/// - IPTV is mostly HLS. AVPlayer is Apple's native HLS player: hardware decoding, low CPU, and it handles server-side
///   ad insertion (#EXT-X-DISCONTINUITY, separate audio/subtitle renditions) seamlessly. VLC 3 froze at those
///   discontinuities (PlutoTV ad breaks); VLC now runs libVLC 4 with a watchdog that reloads stalls - see the
///   VLC watchdog Dev Note in SwiftVLCPlayerView.
/// - Some IPTV streams are not AVPlayer-friendly (odd containers/codecs, MPEG-TS links in M3U lists, streams that
///   stall, or video AVPlayer cannot decode - e.g. some streams on the tvOS Simulator play audio with no video).
///   VLC plays far more formats, so it is the fallback.
///
/// Flow: AVPlayerView's watchdog (AVPlaybackController) detects AVPlayer failures and calls onPlaybackFailure.
/// The URL is added to avPlayerFailedURLs, the view re-renders, and VLCPlayerView plays that stream instead.
/// VLC's own watchdog then handles stalls (reload) and, as the last resort, shows the unplayable overlay.
/// avPlayerFailedURLs lives in @State, so it lasts for this view's lifetime (the app session), not across launches.
struct UnifiedPlayerView: View {

    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]

    /// IPTV stream URLs AVPlayer failed to play this session. These play through VLC instead.
    @State private var avPlayerFailedURLs: Set<URL> = []

    var body: some View {
        if let channel = swiftDataController.selectedChannel,
           channel.deviceId == IPTVImporter.iptvDeviceId,
           not(avPlayerFailedURLs.contains(channel.url)) {
            AVPlayerView(channel: channel) { failedURL in
                avPlayerFailedURLs.insert(failedURL)
            }
        } else {
            // HDHomeRun channels, IPTV fallback, and no channel selected (VLC handles a nil channel).
            VLCPlayerView()
        }
    }
}
