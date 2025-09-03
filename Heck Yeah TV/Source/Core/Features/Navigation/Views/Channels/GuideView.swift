//
//  GuideView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct FocusKey: Identifiable, Hashable {
    let id: String
    let col: Int
}

struct GuideView: View {
    
    let rowHPad: CGFloat = 20
    let corner: CGFloat = 14
    
    @Environment(GuideStore.self) var guideStore

    @FocusState private var focusedChannel: FocusKey?
    @State private var preferredCol: Int = 0
    
    var body: some View {
        VStack {
            ShowFavorites()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(guideStore.visibleChannels) { channel in
                            HStack {
                                Button {
                                    guideStore.selectedChannel = channel
                                    withAnimation(.easeOut(duration: 0.25)) { guideStore.isGuideVisible = false }
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(channel.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                            .frame(width: 420, alignment: .leading)
                                        GuideSubTitleView(channel: channel)
                                    }
                                }
                                .focused($focusedChannel,
                                         equals: FocusKey(id: channel.id,
                                                          col: 0))
#if os(iOS) || os(macOS)
                                .foregroundStyle(Color.white)
#endif
                                Spacer()
                                
                                Button {
                                    guideStore.toggleFavorite(channel)
                                } label: {
                                    Image(systemName: guideStore.isFavorite(channel) ? "star.fill" : "star")
                                        .renderingMode(.template)
                                }
                                .focused($focusedChannel,
                                         equals: FocusKey(id: channel.id,
                                                          col: 1))
                                .tint(guideStore.isFavorite(channel) ? Color.yellow : Color.white)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, rowHPad)
                            .frame(maxWidth: .infinity, alignment: .leading)
#if os(tvOS)
                            .focusSection()
                            .defaultFocus($focusedChannel, FocusKey(id: channel.id,
                                                                    col: preferredCol))
#endif
                            .background {
                                if guideStore.selectedChannel == channel {
                                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                                        .fill(Color.mainAppGreen.opacity(0.22))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: corner, style: .continuous)
                                                .stroke(Color.mainAppGreen.opacity(0.22), lineWidth: 1)
                                        )
                                }
                            }
                        }
                    }
                }
                .onChange(of: focusedChannel) { _, newValue in
                    preferredCol = newValue?.col ?? preferredCol
                }
                
                //Initial scroll, then focus (next runloop)
                .task {
                    if let id = guideStore.selectedChannel?.id ?? guideStore.visibleChannels.first?.id {
                        withAnimation(.easeOut) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                        DispatchQueue.main.async {
                            focusedChannel = FocusKey(id: id, col: preferredCol)
                        }
                    }
                }
            }
#if os(tvOS)
            .background(Color.clear)
#else
            .background(Color.black.opacity(0.35))
#endif
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
        }
    }
}

#Preview() {
    let channel = HDHomeRunChannel(guideNumber: "8.1",
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
