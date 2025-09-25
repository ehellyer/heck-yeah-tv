//
//  TabContainerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct TabContainerView: View {
    
    @Environment(GuideStore.self) var guideStore
    @State private var preferredCol: Int = 0
    @FocusState var focus: FocusTarget?
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
    
    var body: some View {
        TabView(selection: selectedTab) {
            
            Tab(TabSection.recents.title,
                systemImage: TabSection.recents.systemImage,
                value: TabSection.recents) {
                RecentsView()
//                    .focused($focus,
//                             equals: FocusTarget.tab(tabSection: TabSection.recents))
            }
            
            Tab(TabSection.channels.title,
                systemImage: TabSection.channels.systemImage,
                value: TabSection.channels) {
                ChannelsContainer(focus: $focus)
//                    .focused($focus,
//                             equals: FocusTarget.tab(tabSection: TabSection.channels))
            }
            
            Tab(TabSection.search.title,
                systemImage: TabSection.search.systemImage,
                value: TabSection.search) {
                SearchView()
//                    .focused($focus,
//                             equals: FocusTarget.tab(tabSection: TabSection.search))
            }
            
            Tab(TabSection.settings.title,
                systemImage: TabSection.settings.systemImage,
                value: TabSection.settings) {
                SettingsView()
//                    .focused($focus,
//                             equals: FocusTarget.tab(tabSection: TabSection.settings))
            }
        }
        .padding()
        .background(Color.clear)
        
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
#endif // !os(iOS)
        
#if !os(iOS)
        .onMoveCommand { direction in
            handleOnMoveCommand(direction)
        }
#endif
        
    }
    
#if !os(iOS)
    
    private func handleOnMoveCommand(_ direction: MoveCommandDirection) {
        print(">>> func handleOnMoveCommand(_ direction: \(direction)), FocusTarget: \(self.focus?.debugDescription ?? "unknown"), ")
        
        switch (self.focus, direction) {

            case (.guide(let id, _), .up):
                if guideStore.visibleChannels.first?.id == id {
                    lastGuideFocusedTarget = focus
                    withAnimation {
                        focus = .favoritesToggle
                    }
                }

            case (.favoritesToggle, .right),
                (.favoritesToggle, .left),
                (.favoritesToggle, .down):

                // from Favorites to guide when either <LEFT> or <RIGHT> on favorites toggle.
                withAnimation {
                    if let channelId = guideStore.visibleChannels.first?.id {
                        focus = FocusTarget.guide(channelId: channelId, col: 1)
                    }
                }

            case (.guide(_, let col), .left):
                // from guide channel col <LEFT> to favorites
                if col == 1 {
                    lastGuideFocusedTarget = focus
                    withAnimation {
                        focus = .favoritesToggle
                    }
                }
            default:
                break
        }
    }
#endif // !os(iOS)
}

// MARK: - Previews

#if DEBUG && targetEnvironment(simulator)
private struct PreviewTabContainerView: View {
    
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
            TabContainerView()
                .environment(guideStore)
                .ignoresSafeArea(.all)
        }
        .task {
            // This block runs when the view appears
            await guideStore.load(streams: [stream], tunerChannels: [channel])
        }
    }
}

#Preview {
    PreviewTabContainerView()
        .ignoresSafeArea(.all)
}
#endif // DEBUG && targetEnvironment(simulator)
