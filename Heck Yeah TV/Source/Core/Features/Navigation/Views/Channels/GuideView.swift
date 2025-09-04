//
//  GuideView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideView: View {
    
    private let corner: CGFloat = 14
    
    @Environment(GuideStore.self) var guideStore
    @FocusState private var focus: FocusTarget?
    @State private var preferredCol: Int = 0
    private var showFavoritesOnly: Binding<Bool> {
        Binding(
            get: { guideStore.showFavoritesOnly },
            set: { guideStore.showFavoritesOnly = $0 }
        )
    }
    
    var body: some View {
        VStack {
            ShowFavorites(showFavoritesOnly: showFavoritesOnly)
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(guideStore.visibleChannels.enumerated()), id: \.element.id) { index, channel in
                            GuideRow(channel: channel, row: index, focus: $focus)
                                .defaultFocus($focus, FocusTarget.guide(row: index, col: preferredCol))
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
                    .focusSection()
//#if os(tvOS)

//#endif
                    .padding(.leading, 0)
                    .padding(.trailing, 60)
                }
                
                // ScrollView handler of change of focus.
                .onChange(of: focus) {
                    guard let focus, case let FocusTarget.guide(_, col) = focus else { return }
                    preferredCol = col
                }
                
                //Initial scroll, then focus (next runloop)
                .task {
                    
                    if let id = guideStore.selectedChannelIndex {
                        withAnimation(.easeOut) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                        DispatchQueue.main.async {
                            focus = FocusTarget.guide(row: id, col: preferredCol)
                        }
                    }
                }
            }
#if os(tvOS)
            .background(Color.clear)
#else
            //.background(Color.black.opacity(0.35))
#endif
            //.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
        }
        

    }
}

#Preview {
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
