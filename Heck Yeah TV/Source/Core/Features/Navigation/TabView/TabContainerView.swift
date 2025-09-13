//
//  TabContainerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

// MARK: - Root Shell: picks the right container per platform

private struct BackgroundView: View {
    
    var body: some View {
        Color.black.opacity(0.5)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
#if os(tvOS)
//            .focusable(false)
#endif
    }
}

struct TabContainerView: View {
    
    @Environment(GuideStore.self) var guideStore
    @State private var preferredCol: Int = 0
    @FocusState private var focus: FocusTarget?
    @State private var lastGuideFocusedTarget: FocusTarget?
    
    private var selectedTab: Binding<TabSection> {
        Binding(
            get: {
                guideStore.selectedTab
            },
            set: {
                guideStore.selectedTab = $0
            }
        )
    }
    
    private var guideFocusTarget: FocusTarget? {
        if let lastFocus = lastGuideFocusedTarget {
            return lastFocus
        }
        
        if let first = guideStore.visibleChannels.first?.id {
            let target = FocusTarget.guide(channelId: first, col: 0)
            return target
        }
        
        return nil
    }
    
    var body: some View {
        
        ZStack {
            
            BackgroundView()
            TabView(selection: selectedTab) {
                
                Tab(TabSection.last.title,
                    systemImage: TabSection.last.systemImage,
                    value: TabSection.last) {
                    LastChannelView()
                }
                
                Tab(TabSection.recents.title,
                    systemImage: TabSection.recents.systemImage,
                    value: TabSection.recents) {
                    RecentsView()
                }
                
                Tab(TabSection.channels.title,
                    systemImage: TabSection.channels.systemImage,
                    value: TabSection.channels) {
                    ChannelsContainer()
                }
                
                Tab(TabSection.search.title,
                    systemImage: TabSection.search.systemImage,
                    value: TabSection.search) {
                    SearchView()
                }
                
                Tab(TabSection.settings.title,
                    systemImage: TabSection.settings.systemImage,
                    value: TabSection.settings) {
                    SettingsView()
                }
            }
        }
        .onChange(of: focus) {
            DispatchQueue.main.async {
                print("<<< Focus onChange: \(self.focus?.debugDescription ?? "unknown")")
            }
        }
       
        
#if !os(iOS)
        // Support for dismissing the tabview by tapping menu on Siri remote for tvOS or esc key on keyboard.
        .onExitCommand {
            withAnimation(.easeOut(duration: 0.25)) {
                guideStore.isGuideVisible = false
            }
        }
#endif
        
#if !os(iOS)
        .onMoveCommand { direction in
            handleOnMoveCommand(direction)
        }
#endif

    }
    
#if !os(iOS)
    
    private func handleOnMoveCommand(_ direction: MoveCommandDirection) {
        print(">>> Move detected: FocusTarget: \(self.focus?.debugDescription ?? "unknown"), Direction: \(direction)")
        
        switch (self.focus, direction) {
                
            case (.guide(let id, _), .up):
                if guideStore.visibleChannels.first?.id == id {
                    lastGuideFocusedTarget = focus
                    withAnimation {
                        focus = .favoritesToggle
                    }
                }
                
            case (.none, .left),
                (.none, .right),
                (.favoritesToggle, .right),
                (.favoritesToggle, .left),
                (.favoritesToggle, .down):
                
                // from Favorites to guide when either <LEFT> or <RIGHT> on favorites toggle.
                withAnimation {
                    focus = guideFocusTarget
                }
                
            case (.guide(_, let col), .left):
                // from guide channel col <LEFT> to favorites
                if col == 0 {
                    lastGuideFocusedTarget = focus
                    withAnimation {
                        focus = .favoritesToggle
                    }
                }
            default:
                break
        }
    }
#endif
}

// MARK: - Previews

#Preview() {

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
    
    TabContainerView()
        .environment(guideStore)
        .ignoresSafeArea(.all)
}

