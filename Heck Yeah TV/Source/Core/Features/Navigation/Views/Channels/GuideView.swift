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
    @FocusState.Binding var focus: FocusTarget?
    @Binding var preferredCol: Int 
    private var showFavoritesOnly: Binding<Bool> {
        Binding(
            get: { guideStore.showFavoritesOnly },
            set: { guideStore.showFavoritesOnly = $0 }
        )
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(guideStore.visibleChannels.enumerated()), id: \.element.id) { index, channel in
                        GuideRow(channel: channel, row: index, focus: $focus)
                    }
                }
                .background(Color.clear)
                .padding(0)
            }
            
            .background(Color.clear)
            
            // ScrollView handler of change of focus.
            .onChange(of: focus) {
                guard let focus, case let FocusTarget.guide(rowId, col) = focus else { return }
                preferredCol = col
                withAnimation(.easeOut) {
                    proxy.scrollTo(rowId, anchor: .center)
                }
            }
            
            .onAppear {
                if let rowId = guideStore.selectedChannelIndex {
                    withAnimation(.easeOut) {
                        proxy.scrollTo(rowId, anchor: .center)
                    }
                }
            }
            
            //Initial scroll, then focus (next runloop)
            .task {
                if let rowId = guideStore.selectedChannelIndex {
                    withAnimation(.easeOut) {
                        proxy.scrollTo(rowId, anchor: .center)
                    }
                }
            }
            
        }
        .background(Color.clear)
    }
        
}



struct Preview_Guide: View {
    @State var preferredCol: Int = 0
    @FocusState var focus: FocusTarget?
    @State var channel = HDHomeRunChannel(guideNumber: "8.1",
                                          guideName: "WRIC-TV",
                                          videoCodec: "MPEG2",
                                          audioCodec: "AC3",
                                          hasDRM: true,
                                          isHD: true ,
                                          url: "http://192.168.50.250:5004/auto/v8.1")
    @State var stream = IPStream(channelId:  "PlutoTVTrueCrime.us",
                                 feedId: "Austria",
                                 title: "Pluto TV True Crime",
                                 url:"https://amg00793-amg00793c5-firetv-us-4068.playouts.now.amagi.tv/playlist.m3u8",
                                 referrer: nil,
                                 userAgent: nil,
                                 quality: "2160p")
    
    
    
    var body: some View {
        let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
        return GuideView(focus: $focus, preferredCol: $preferredCol).environment(guideStore)
    }
}

#Preview {
    Preview_Guide()
}
