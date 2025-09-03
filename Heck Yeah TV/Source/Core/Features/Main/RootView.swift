//
//  RootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct RootView: View {
    
    @State private var selectedTab: TabSection = .last
    @Environment(GuideStore.self) private var guideStore
    
    // Build a binding to your VLCPlayerView's `channel: GuideChannel?`
    private var channelBinding: Binding<GuideChannel?> {
        Binding(
            get: { guideStore.selectedChannel },
            set: { guideStore.selectedChannel = $0 }
        )
    }
    
    var body: some View {
        ZStack {
            
            ZStack {
                VLCPlayerView(channel: channelBinding)
                    .ignoresSafeArea()
                
                if guideStore.isGuideVisible {  
                    NavigationRootView(selectedTab: $selectedTab)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                } else {
                    GuideActivationView()
                }
            }
            
#if os(macOS)
            // macOS: arrow keys re-show the guide
            .background( MacArrowKeyCatcher {
                withAnimation {
                    guideStore.isGuideVisible = true
                }
            })
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
    
    RootView()
        .environment(guideStore)
}
