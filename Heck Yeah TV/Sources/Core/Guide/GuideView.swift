//
//  GuideView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideView: View {
    
    @Environment(GuideStore.self) var store
    
//    var body: some View {
//        NavigationView {
//            List(store.visibleChannels) { ch in
//                HStack {
//                    Text(ch.title).lineLimit(1)
//                    Spacer()
//                    Button("Play") {
//                        store.select(ch)
//                    }
//                }
//            }
//            .navigationTitle("Guide")
//
//            // Player pane reacts to selection automatically
//            VLCPlayerView(channel: Binding(
//                get: { store.selectedChannel },
//                set: { _ in } // no-op; player drives no state back
//            ))
//            .ignoresSafeArea() // if you want edge-to-edge video
//            .background(Color.black)
//        }
//    }
    
    var body: some View {
        NavigationView {
            List(store.visibleChannels) { channel in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.title)
                            .font(.headline)
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            if let n = channel.number { Text(n).font(.caption).foregroundStyle(.secondary) }
                            if channel.isHD { Text("HD").font(.caption2).padding(.horizontal, 4).padding(.vertical, 2).overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.4))) }
                            if channel.hasDRM { Text("DRM").font(.caption2).padding(.horizontal, 4).padding(.vertical, 2).overlay(RoundedRectangle(cornerRadius: 4).stroke(.secondary.opacity(0.4))) }
                        }
                    }
                    Spacer()
                    Button {
                        store.toggleFavorite(channel)
                    } label: {
                        Image(systemName: store.isFavorite(channel) ? "star.fill" : "star")
                    }
                    .buttonStyle(.borderless)
                    
                    Button("Play") {
                        store.select(channel)
                    }
                }
            }
            .navigationTitle("Guide")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        store.showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: store.showFavoritesOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .help("Toggle favorites filter")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Last") {
                        store.switchToLastChannel()
                    }
                    .disabled(store.lastPlayedChannel == nil)
                }
            }
            
            // Player pane reacts to selection automatically
            VLCPlayerView(channel: Binding(
                get: {
                    store.selectedChannel
                },
                set: { _ in
                    // no-op; player drives no state back
                }
            ))
            .ignoresSafeArea()
            .background(Color.black)
        }
    }
}

#Preview() {
    let channel = Channel(guideNumber: "abc",
                          guideName: "ABC",
                          videoCodec: nil,
                          audioCodec: nil,
                          hasDRM: true,
                          isHD: true ,
                          url: "https://abc.com")
    let stream = IPStream(channelId: "fox",
                          feedId: "fox",
                          title: "FOX",
                          url: "https://fox.com",
                          referrer: nil,
                          userAgent: nil,
                          quality: "1080p")
    
    let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
    
    GuideView()
        .environment(guideStore)
}
