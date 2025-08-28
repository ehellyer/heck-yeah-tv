//
//  GuideView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideView: View {
    
    @Environment(GuideStore.self) var guideStore
    
#if os(tvOS)
    @FocusState private var focusedChannel: String?
#endif
    
    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 0) {
                List(guideStore.visibleChannels) { channel in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            
                            HStack {
                                Button {
                                    guideStore.selectedChannel = channel
                                    withAnimation(.easeOut(duration: 0.25)) {
                                        guideStore.isGuideVisible = false
                                    }
                                } label: {
                                    Text(channel.title)
                                        .font(.headline)
                                        .lineLimit(1)
                                        
                                }
                                .id(channel.id)
                            }
                            GuideSubTitleView(channel: channel)
                        }
                        Spacer()
                        if guideStore.selectedChannel == channel {
                            Image(systemName: "play.circle.fill")
                        }
                        Button {
                            guideStore.toggleFavorite(channel)
                        } label: {
                            Image(systemName: guideStore.isFavorite(channel) ? "star.fill" : "star")
                        }
                        .buttonStyle(.borderless)
                    }
                    //.contentShape(Rectangle())
                    .onTapGesture {
                        guideStore.selectedChannel = channel
                        withAnimation(.easeOut(duration: 0.25)) {
                            guideStore.isGuideVisible = false
                        }
                    }
                    .listRowBackground(
                        (guideStore.selectedChannel == channel ? Color.blue.opacity(0.2) : Color.clear)
                    )
                }
            }
#if os(tvOS)
            .padding(50)
#endif
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(overlayMaterial)
            
            // 1) When the guide appears, scroll to the selected item
            .onChange(of: guideStore.isGuideVisible) { _, _ in
                guard guideStore.isGuideVisible, let id = guideStore.selectedChannel?.id else { return }
                // Defer one turn so List has layout before we scroll.
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
#if os(tvOS)
                focusedChannel = id
#endif
            }
            
            // 2) Also keep it centered when selection changes while visible
            .onChange(of: guideStore.selectedChannel) { _, _ in
                guard guideStore.isGuideVisible, let id = guideStore.selectedChannel?.id else { return }
                withAnimation(.easeInOut) {
                    proxy.scrollTo(id, anchor: .center)
                }
#if os(tvOS)
                focusedChannel = id
#endif
            }
            
            // 3) Initial mount (e.g., app launch with a preselected channel)
            .task {
                if let id = guideStore.selectedChannel?.id {
                    proxy.scrollTo(id, anchor: .center)
#if os(tvOS)
                    focusedChannel = id
#endif
                }
            }
        }
    }
    
    @ViewBuilder private var overlayMaterial: some View {
#if os(tvOS)
        Color.black.opacity(0.35) // tvOS fallback (no system material)
#else
        ZStack {
        }
        .background(.ultraThinMaterial)
#endif
    }
}

#Preview() {
    let channel = Channel(guideNumber: "8.1",
                          guideName: "WRIC-TV",
                          videoCodec: "MPEG2",
                          audioCodec: "AC3",
                          hasDRM: true,
                          isHD: true ,
                          url: "http://192.168.50.250:5004/auto/v8.1")
    let stream = IPStream(channelId:  "PlutoTVTrueCrime.us",
                          feedId: "Austria",
                          title: "Pluto TV True Crime",
                          url:"http://cfd-v4-service-channel-stitcher-use1-1.prd.pluto.tv/stitch/hls/channel/615333098185f00008715a56/master.m3u8?appName=web&appVersion=unknown&clientTime=0&deviceDNT=0&deviceId=1b2049e1-4b81-11ef-a8ac-e146e4e7be02&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=unknown&includeExtendedEvents=false&serverSideAds=false&sid=03c264ad-dc34-4e0b-b96f-6cfb4c0f6b37",
                          referrer: nil,
                          userAgent: nil,
                          quality: "2160p")
    
    let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
    
    GuideView()
        .environment(guideStore)
}
