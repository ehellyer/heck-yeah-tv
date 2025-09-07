//
//  AppContainerView.swift
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
            Color.black.opacity(0.5)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
#if os(tvOS)
        .focusable(false)
#endif
    }
}

struct AppContainerView: View {
    
    @Environment(GuideStore.self) var guideStore
    @Binding var selectedTab: TabSection
    @FocusState private var focus: FocusTarget?
    private var showFavoritesOnly: Binding<Bool> {
        Binding(
            get: { guideStore.showFavoritesOnly },
            set: { guideStore.showFavoritesOnly = $0 }
        )
    }
    
    var body: some View {
        
        ZStack{
            BackgroundView()
            TabView(selection: $selectedTab) {
                
                Tab(TabSection.last.title,
                    systemImage: TabSection.last.systemImage,
                    value: TabSection.last) {
                    LastChannelView()
                        .background(Color.black.opacity(0.01))
                }
                
                Tab(TabSection.recents.title,
                    systemImage: TabSection.recents.systemImage,
                    value: TabSection.recents) {
                    RecentsView()
                        .background(Color.black.opacity(0.01))
                }
                
                Tab(TabSection.channels.title,
                    systemImage: TabSection.channels.systemImage,
                    value: TabSection.channels) {
                    VStack {
                        ShowFavorites(showFavoritesOnly: showFavoritesOnly, focus: $focus)
#if !os(iOS)
                            .onMoveCommand { direction in
                                favoritesOnMoveCommand(direction)
                            }
#endif
                        GuideView(focus: $focus)
                            .background(Color.black.opacity(0.01))
#if !os(iOS)
                            .onMoveCommand { direction in
                                guideViewOnMoveCommand(direction)
                            }
#endif
                    }
                    .background(Color.clear, ignoresSafeAreaEdges: .all)
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
            .padding(10)
            
//            .onAppear {
//                let appearance = UITabBarAppearance()
//                appearance.configureWithTransparentBackground()
//                appearance.backgroundColor = .clear
//                UITabBar.appearance().standardAppearance = appearance
//                UITabBar.appearance().scrollEdgeAppearance = appearance
//                
//            }
        }
        
        //Dismiss without changing state.
#if !os(iOS)
        .onExitCommand {
            withAnimation(.easeOut(duration: 0.25)) {
                guideStore.isGuideVisible = false
            }
        }
#endif
    }

#if !os(iOS)
    private func favoritesOnMoveCommand(_ direction: MoveCommandDirection) {
        print("Favorites swipe >>> Focus \(focus?.debugDescription ?? "unknown"), Direction: \(direction)")
        
        switch (focus, direction) {
            case (.favoritesToggle, .right), (.favoritesToggle, .left):
                withAnimation {
                    focus = .guide(row:1, col: 1)
                }
            case (.favoritesToggle, .down):
                // from Favorites <DOWN> to guide
                withAnimation {
                    focus = .guide(row: 0, col: 0)
                }
            case (.favoritesToggle, .up):
                // from favorites <UP> to channels tab
                withAnimation {
                    focus = .tab(.channels)
                }
            default:
                break
        }
    }
    
    private func guideViewOnMoveCommand(_ direction: MoveCommandDirection) {
        print("Guide swipe >>> Focus \(focus?.debugDescription ?? "unknown"), Direction: \(direction)")
        
        switch (focus, direction) {
                
            case (.guide(_, let col), .left):
                // from guide channel col <LEFT> to favorites
                if col == 0 {
                    withAnimation {
                        focus = .favoritesToggle
                    }
                }
            case (.guide(let row, _), .up):
                // from guide at row 0, <UP> to favorites
                if row == 0 {
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
//
//#Preview("Adaptive Container") {
//
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
//                          url:"http://cfd-v4-service-channel-stitcher-use1-1.prd.pluto.tv/stitch/hls/channel/615333098185f00008715a56/master.m3u8?appName=web&appVersion=unknown&clientTime=0&deviceDNT=0&deviceId=1b2049e1-4b81-11ef-a8ac-e146e4e7be02&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=unknown&includeExtendedEvents=false&serverSideAds=false&sid=03c264ad-dc34-4e0b-b96f-6cfb4c0f6b37",
//                          referrer: nil,
//                          userAgent: nil,
//                          quality: "2160p")
//
//    let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
//
//
//    AppContainerView(selectedTab: .constant(.channels))
//        .environment(guideStore)
//}
//
