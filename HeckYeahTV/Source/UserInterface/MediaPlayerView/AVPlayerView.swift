//
//  AVPlayerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/26/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import AVKit

struct AVPlayerView: View {
    
    let channel: Channel
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                loadChannel()
            }
            .onDisappear {
                player.pause()
            }
            .onChange(of: channel.id) { _, _ in
                loadChannel()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase != .active {
                    player.pause()
                }
            }
            .onChange(of: appState.isPlayerPaused) { _, newValue in
                if newValue {
                    player.pause()
                } else {
                    player.play()
                }
            }
    }
    
    private func loadChannel() {
        logDebug("AVPlayer: Loading IPTV channel '\(channel.title)' from \(channel.url.absoluteString)")
        
        let assetOptions: [String: Any] = [
            AVURLAssetAllowsConstrainedNetworkAccessKey: true,
            AVURLAssetAllowsExpensiveNetworkAccessKey: true
        ]
        
        let asset = AVURLAsset(url: channel.url, options: assetOptions)
        let item = AVPlayerItem(asset: asset)
        
        player.replaceCurrentItem(with: item)
        
        if !appState.isPlayerPaused {
            player.play()
        }
    }
}
