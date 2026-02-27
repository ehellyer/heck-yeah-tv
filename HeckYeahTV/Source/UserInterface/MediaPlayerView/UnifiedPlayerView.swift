//
//  UnifiedPlayerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/25/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI


/// Unified player view that automatically switches between VLC and AVPlayer based on channel type.
/// - IPTV channels (deviceId == IPTVImporter.iptvDeviceId) use AVPlayer for HLS streams
/// - HDHomeRun channels (deviceId != IPTVImporter.iptvDeviceId) use VLC for MPEG-TS streams
struct UnifiedPlayerView: View {
    
//    @Environment(\.scenePhase) private var scenePhase
//    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
//    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
//    
    var body: some View {
        ZStack {
//            if let channelId = appState.selectedChannel,
//               let channel = swiftDataController.channel(for: channelId) {
                
//                if channel.deviceId == IPTVImporter.iptvDeviceId {
//                    // IPTV channels use AVPlayer (supports HLS)
//                    AVPlayerView(channel: channel)
//                } else {
                    // HDHomeRun channels use VLC (supports MPEG-TS)
                    VLCPlayerView()
//                }
//            } else {
//                // No channel selected - show blank screen
//                Color.black
//                    .ignoresSafeArea()
//            }
        }
    }
}
