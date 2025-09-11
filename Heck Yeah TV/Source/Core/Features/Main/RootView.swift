//
//  RootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct RootView: View {
    
    @State private var fadeTask: Task<Void, Never>?
    @State private var showPlayToast = false
    @Environment(GuideStore.self) private var guideStore
    
    // Binding parts of GuideStore to VLCPlayerView: PlatformViewRepresentable
    private var channel: Binding<GuideChannel?> {
        Binding(
            get: { guideStore.selectedChannel },
            set: { guideStore.selectedChannel = $0 }
        )
    }
    private var isPlaying: Binding<Bool> {
        Binding(
            get: { guideStore.isPlaying },
            set: { guideStore.isPlaying = $0 }
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            VLCPlayerView(isPlaying: isPlaying, selectedChannel: channel)
                .ignoresSafeArea(.all)
            
            if guideStore.isGuideVisible {
                TabContainerView()
                    .transition(.opacity)
                    .ignoresSafeArea(.all)
            } else {
                TabActivationView()
                    .ignoresSafeArea(.all)
            }
            
            // Persistent “Paused” badge when not playing
            if guideStore.isPlaying == false {
                PlaybackBadge(text: "Paused", systemName: "pause.fill")
                    .transition(.opacity)
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
            }
            if guideStore.isPlaying && showPlayToast {
                PlaybackBadge(text: "Play", systemName: "play.fill")
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
            }
        }

        .onChange(of: guideStore.isPlaying, { oldValue, newValue in
            fadeTask?.cancel()
            fadeTask = nil
            
            if newValue == false {
                showPlayToast = false
            } else {
                fadeTask = Task { @MainActor in
                    showPlayToast = true
                    do {
                        try await Task.sleep(nanoseconds: 2_000_000_000) //2 Seconds
                        try Task.checkCancellation()
                        showPlayToast = false
                    } catch {
                        // Task Cancelled - no op.
                    }
                }
            }
        })
#if os(tvOS)
        // VLCPlayerView global handler for play/pause
        .onPlayPauseCommand {
            guideStore.isPlaying.toggle()
        }
#endif
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
