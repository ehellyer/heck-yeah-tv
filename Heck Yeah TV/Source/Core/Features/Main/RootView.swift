//
//  RootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

struct RootView: View {
    @Binding var isReady: Bool
    
    var body: some View {
        BootGateView(isReady: $isReady) {
#if os(tvOS)
            MainAppContentView()
                .ignoresSafeArea()
#elseif os(macOS)
            MainAppContentView()
                .frame(minWidth: 900, minHeight: 507)
#else
            MainAppContentView()
#endif
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
private struct PreviewRootView: View {
    
    @FocusState var focus: FocusTarget?
    @State private var guideStore = GuideStore()
    @State private var channel = HDHomeRunChannel(guideNumber: "8.1",
                                                  guideName: "WRIC-TV",
                                                  videoCodec: "MPEG2",
                                                  audioCodec: "AC3",
                                                  hasDRM: true,
                                                  isHD: true ,
                                                  url: "http://192.168.50.250:5004/auto/v8.1")
    @State private var stream = IPStream(channelId:  "PlutoTVTrueCrime.us",
                                         feedId: "Austria",
                                         title: "Pluto TV True Crime",
                                         url:"https://amg00793-amg00793c5-firetv-us-4068.playouts.now.amagi.tv/playlist.m3u8",
                                         referrer: nil,
                                         userAgent: nil,
                                         quality: "2160p")
    
    var body: some View {
        VStack {
            RootView(isReady: .constant(true)).environment(guideStore)
        }
        .task {
            // This block runs when the view appears
            await guideStore.load(streams: [stream], tunerChannels: [channel])
        }
    }
}

#Preview {
    PreviewRootView()
        .ignoresSafeArea(.all)
}
#endif
