//
//  NavigationRootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

// MARK: - Root Shell: picks the right container per platform

private struct BackgroundView: View {
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
#if os(tvOS)
        .focusable(false)
#endif
    }
}

struct NavigationRootView: View {
    
    @Environment(GuideStore.self) var guideStore
    @Binding var selectedTab: TabSection
    
    var body: some View {
        ZStack{
            BackgroundView()

#if os(tvOS)
            NavigationTVView(selectedTab: $selectedTab) {
                contentView(for: selectedTab)
            }
            //Dismiss without changing state.
            .onExitCommand {
                withAnimation(.easeOut(duration: 0.35)) {
                    guideStore.isGuideVisible = false
                }
            }
          
#elseif os(iOS)
            Group {
                NavigationIOSView(selectedTab: $selectedTab) {
                    contentView(for: selectedTab)
                }
            }
#elseif os(macOS)
            NavigationMacView(selectedTab: $selectedTab) {
                contentView(for: selectedTab)
            }
            //Dismiss without changing state.
            .onExitCommand {
                withAnimation(.easeOut(duration: 0.25)) {
                    guideStore.isGuideVisible = false
                }
            }
#endif
        }
    }
    
    @ViewBuilder
    private func contentView(for tab: TabSection) -> some View {
        switch tab {
            case .last:     LastChannelView()
            case .recents:  RecentsView()
            case .channels: GuideView()
            case .search:   SearchView()
            case .settings: SettingsView()
        }
    }
}

// MARK: - Previews

#Preview("Adaptive Container") {
    
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
    
    
    NavigationRootView(selectedTab: .constant(.channels))
        .environment(guideStore)
}

