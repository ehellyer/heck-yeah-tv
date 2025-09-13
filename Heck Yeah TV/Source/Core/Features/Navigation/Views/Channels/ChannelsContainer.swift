//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

private struct FocusHub: View {
    var body: some View { Color.clear.frame(width: 1, height: 1) }
}

struct ChannelsContainer: View {
    
    @Environment(GuideStore.self) var guideStore
    @FocusState var focus: FocusTarget?
    
    private var showFavoritesOnly: Binding<Bool> {
        Binding(
            get: {
                guideStore.showFavoritesOnly
            },
            set: {
                guideStore.showFavoritesOnly = $0
            }
        )
    }
    
    private var initialFocusTarget: FocusTarget {
        if let id = guideStore.selectedChannel?.id {
            return .guide(channelId: id, col: 0)
        } else {
            return .favoritesToggle
        }
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 5) {
            ShowFavorites(showFavoritesOnly: showFavoritesOnly, focus: $focus)
            GuideView(focus: $focus)
        }
//        .defaultFocus($focus, initialFocusTarget)
//        .onAppear {
//            // Also set programmatically in case tvOS ignores defaultFocus due to async population
//            if case .none = focus {
//                focus = initialFocusTarget
//            }
//        }
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
                          url:"https://amg00793-amg00793c5-firetv-us-4068.playouts.now.amagi.tv/playlist.m3u8",
                          referrer: nil,
                          userAgent: nil,
                          quality: "2160p")
    
    let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
    
    ChannelsContainer().environment(guideStore)
        .ignoresSafeArea(.all)
}
