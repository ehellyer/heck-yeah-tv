//
//  AVPlayerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/7/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

// Test code for RootView.swift  (Top Gear)
// AVPlayerView(url: URL(string: "https://amg00793-amg00793c5-firetv-us-4068.playouts.now.amagi.tv/playlist.m3u8")!)

import SwiftUI
import AVKit

struct AssetInfo {
    let title: String?
    let duration: CMTime
    let tracks: [AVAssetTrack]
}

enum PlayerPrepError: Error { case unplayable }

/// Preloads metadata; returns both the info and a ready-to-use player.
func preparePlayer(
    url: URL,
    headers: [String:String] = [:]
) async throws -> (info: AssetInfo, player: AVPlayer) {
    
    // Custom HTTP headers:
    let opts = headers.isEmpty ? nil : ["AVURLAssetHTTPHeaderFieldsKey": headers]
    let asset = AVURLAsset(url: url, options: opts)
    
    // Load what you need *before* creating the player item.
    let (isPlayable, duration, tracks, commonMD) = try await (
        asset.load(.isPlayable),
        asset.load(.duration),
        asset.load(.tracks),
        asset.load(.commonMetadata)   // static (non-timed) metadata
    )
    
    guard isPlayable else { throw PlayerPrepError.unplayable }
    
    let title = try await AVMetadataItem.metadataItems(from: commonMD,
                                                       withKey: AVMetadataKey.commonKeyTitle,
                                                       keySpace: .common).first?.load(.stringValue)
    
    let item = AVPlayerItem(asset: asset)
    let player = AVPlayer(playerItem: item)
    player.automaticallyWaitsToMinimizeStalling = true
    
    return (AssetInfo(title: title, duration: duration, tracks: tracks), player)
}


struct AVPlayerView: View {
    
    let url: URL
    @State private var info: AssetInfo?
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            if let player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
            } else {
                ProgressView("Loading stream…")
            }
            
            if let title = info?.title {
                Text(title).padding(8).background(.ultraThinMaterial).cornerRadius(8)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .task {
            do {
                let result = try await preparePlayer(url: url)
                info = result.info
                player = result.player
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}

//#Preview {
//    AVPlayerView(isPlaying: .constant(true))
//}

