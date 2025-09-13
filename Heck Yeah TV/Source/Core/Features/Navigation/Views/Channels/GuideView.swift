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
        
    var body: some View {
        ScrollViewReader { proxy in
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(guideStore.visibleChannels) { channel in
                        GuideRow(channel: channel, focus: $focus)
                            .id(channel.id)
                    }
                }
                .padding(.vertical, 0)
                
            }
            .background(Color.clear)
//            .onAppear {
//                if let channelId = guideStore.selectedChannel?.id {
//                    Task { @MainActor in
//                        withAnimation(.easeOut) {
//                            proxy.scrollTo(channelId, anchor: .center)
//                        }
//                        
//                        try? await Task.sleep(nanoseconds: 20_000_000) // 0.2 sec
//                        withAnimation(.easeOut(duration: 0.15)) {
//                            if let channelId = guideStore.selectedChannel?.id {
//                                focus = .guide(channelId: channelId, col: 0)
//                            } else {
//                                focus = .favoritesToggle
//                            }
//                        }
//                    }
//                }
//            }
//            
//            .onChange(of: focus) { _, new in
//                if case let .guide(id, _) = new {
//                    withAnimation(.easeOut) {
//                        proxy.scrollTo(id, anchor: .center)
//                    }
//                }
//            }
        }
        
        .background(Color.clear)
    }
}


//struct Preview_Guide: View {
//
//    @FocusState var focus: FocusTarget?
//    @State var channel = HDHomeRunChannel(guideNumber: "8.1",
//                                          guideName: "WRIC-TV",
//                                          videoCodec: "MPEG2",
//                                          audioCodec: "AC3",
//                                          hasDRM: true,
//                                          isHD: true ,
//                                          url: "http://192.168.50.250:5004/auto/v8.1")
//    @State var stream = IPStream(channelId:  "PlutoTVTrueCrime.us",
//                                 feedId: "Austria",
//                                 title: "Pluto TV True Crime",
//                                 url:"https://amg00793-amg00793c5-firetv-us-4068.playouts.now.amagi.tv/playlist.m3u8",
//                                 referrer: nil,
//                                 userAgent: nil,
//                                 quality: "2160p")
//
//    var body: some View {
//        let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
//        return GuideView(focus: $focus).environment(guideStore)
//    }
//}
//
//#Preview {
//    Preview_Guide()
//        .ignoresSafeArea(.all)
//}
