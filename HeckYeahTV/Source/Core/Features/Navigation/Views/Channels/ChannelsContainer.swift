//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelsContainer: View {
    
    @FocusState.Binding var focus: FocusTarget?
    
//    private var initialFocusTarget: FocusTarget {
//        if let id = guideStore.selectedChannel?.id {
//            return .guide(channelId: id, col: 0)
//        } else {
//            return .favoritesToggle
//        }
//    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ShowFavorites(focus: $focus)
            GuideViewRepresentable(focus: $focus)
        }
    }
}

//#Preview {
//    let channel = HDHomeRunChannel(guideNumber: "8.1",
//                                   guideName: "WRIC-TV",
//                                   videoCodec: "MPEG2",
//                                   audioCodec: "AC3",
//                                   hasDRM: true,
//                                   isHD: true ,
//                                   url: "http://192.168.50.250:5004/auto/v8.1")
//    let stream = IPStream(channelId:  "PlutoTVTrueCrime.us",
//                          feedId: "Austria",
//                          title: "Pluto TV True Crime",
//                          url:"https://amg00793-amg00793c5-firetv-us-4068.playouts.now.amagi.tv/playlist.m3u8",
//                          referrer: nil,
//                          userAgent: nil,
//                          quality: "2160p")
//    
//    let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
//    
//    ChannelsContainer().environment(guideStore)
//        .ignoresSafeArea(.all)
//}
