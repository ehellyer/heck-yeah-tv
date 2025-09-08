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

struct TabContainerView: View {
    
    @Environment(GuideStore.self) var guideStore
    @Binding var selectedTab: TabSection
    @FocusState private var focus: FocusTarget?
    @State private var preferredCol: Int = 0
    
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

                        GuideView(focus: $focus, preferredCol: $preferredCol)                            
                            .background(Color.black.opacity(0.01))
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
        
        .onMoveCommand { direction in
            handleOnMoveCommand(direction)
        }
        
        .task {
            guard selectedTab == .channels else { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
            let row = guideStore.selectedChannelIndex ?? 0
            withAnimation(.easeOut(duration: 0.15)) {
                focus = .guide(row: row, col: preferredCol)
            }
        }
        
#if !os(iOS)
        // Support for dismissing the tabview by tapping menu on Siri remote for tvOS and esc key on keyboard for Mac.
        .onExitCommand {
            withAnimation(.easeOut(duration: 0.25)) {
                guideStore.isGuideVisible = false
            }
        }
#endif
    }
    
#if !os(iOS)
    
    private func handleOnMoveCommand(_ direction: MoveCommandDirection) {
        print(">>> Move detected: FocusTarget: \(focus?.debugDescription ?? "unknown"), Direction: \(direction)")
        
        switch (focus, direction) {
                
            case (.favoritesToggle, .right), (.favoritesToggle, .left):
                // from Favorites to guide when either <LEFT> or <RIGHT> on favorites toggle.
                let rowId = guideStore.selectedChannelIndex ?? 0
                focus = .guide(row:rowId, col: preferredCol)
                
            case (.favoritesToggle, .down):
                // from Favorites <DOWN> to guide
                focus = .guide(row: 0, col: preferredCol)
                print("Focus set to: \(focus?.debugDescription ?? "unknown") <<<")
            case (.favoritesToggle, .up):
                // from favorites <UP> to channels tab
                focus = .tab(.channels)
                print("Focus set to: \(focus?.debugDescription ?? "unknown") <<<")
            case (.guide(_, let col), .left):
                // from guide channel col <LEFT> to favorites
                if col == 0 {
                    focus = .favoritesToggle
                    print("Focus set to: \(focus?.debugDescription ?? "unknown") <<<")
                }
            case (.guide(let row, _), .up):
                // from guide at row 0, <UP> to favorites
                if row == 0 {
                    focus = .favoritesToggle
                    print("Focus set to: \(focus?.debugDescription ?? "unknown") <<<")
                }
                
            default:
                break
        }
        print("Focus set to: \(focus?.debugDescription ?? "unknown") <<<")
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
//    TabContainerView(selectedTab: .constant(.channels))
//        .environment(guideStore)
//}
//
