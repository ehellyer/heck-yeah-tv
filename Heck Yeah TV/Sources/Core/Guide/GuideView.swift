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
    
    @State private var selectedChannel: GuideChannel?
    
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
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    store.select(channel)
                    selectedChannel = channel
                }
                .listRowBackground(
                    (selectedChannel == channel ? Color.blue.opacity(0.2) : Color.white)
                )
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
    let channel = Channel(guideNumber: "8.1",
                          guideName: "WRIC-TV",
                          videoCodec: "MPEG2",
                          audioCodec: "AC3",
                          hasDRM: false,
                          isHD: true ,
                          url: "http://192.168.50.250:5004/auto/v8.1")
    let stream = IPStream(channelId:  "PlutoTVTrueCrime.us",
                          feedId: "Austria",
                          title: "Pluto TV True Crime",
                          url:"http://cfd-v4-service-channel-stitcher-use1-1.prd.pluto.tv/stitch/hls/channel/615333098185f00008715a56/master.m3u8?appName=web&appVersion=unknown&clientTime=0&deviceDNT=0&deviceId=1b2049e1-4b81-11ef-a8ac-e146e4e7be02&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=unknown&includeExtendedEvents=false&serverSideAds=false&sid=03c264ad-dc34-4e0b-b96f-6cfb4c0f6b37",
                          referrer: nil,
                          userAgent: nil,
                          quality: nil)
    
    let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
    
    GuideView()
        .environment(guideStore)
}
