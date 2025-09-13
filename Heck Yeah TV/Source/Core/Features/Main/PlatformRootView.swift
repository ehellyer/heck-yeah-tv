//
//  PlatformRootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

struct PlatformRootView: View {
    @Binding var isReady: Bool
    
    var body: some View {
        BootGateView(isReady: $isReady) {
#if os(iOS)
            NavigationStack {
                RootView()
            }
#elseif os(tvOS)
            RootView()
                .ignoresSafeArea()
#elseif os(macOS)
            RootView()
                .frame(minWidth: 900, minHeight: 507)
#else
            RootView()
#endif
        }
    }
}

#Preview {
    let channel = HDHomeRunChannel(guideNumber: "8.1",
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
    
    PlatformRootView(isReady: .constant(true))
        .environment(guideStore)
}
