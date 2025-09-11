//
//  ChannelsContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelsContainer: View {
    
    @Environment(GuideStore.self) var guideStore
    @FocusState private var focus: FocusTarget?
    
    private var showFavoritesOnly: Binding<Bool> {
        Binding(
            get: {
                guideStore.showFavoritesOnly
            },
            set: {
                guideStore.showFavoritesOnly = $0
            }
        )
    }
    
    var body: some View {
        
        VStack {
            ShowFavorites(showFavoritesOnly: showFavoritesOnly, focus: $focus)
            GuideView(focus: $focus)
        }

#if !os(iOS)
        .onMoveCommand { direction in
            handleOnMoveCommand(direction)
        }
#endif
        .task {
            try? await Task.sleep(nanoseconds: 20_000_000) // 0.2 sec
            withAnimation(.easeOut(duration: 0.15)) {
                let row = guideStore.selectedChannelIndex ?? 0
                focus = .guide(row: row, col: 0)
            }
        }
    }
    
#if !os(iOS)
    
    private func handleOnMoveCommand(_ direction: MoveCommandDirection) {
        print(">>> Move detected: FocusTarget: \(focus?.debugDescription ?? "unknown"), Direction: \(direction)")
        
//        switch (focus, direction) {
//                
//            case (.favoritesToggle, .right), (.favoritesToggle, .left):
//                // from Favorites to guide when either <LEFT> or <RIGHT> on favorites toggle.
//                //withAnimation {
//                let rowId = guideStore.selectedChannelIndex ?? 0
//                focus = .guide(row: rowId, col: 0)
//                //}
//            case (.favoritesToggle, .down):
//                // from Favorites <DOWN> to guide
//                withAnimation {
//                    focus = .guide(row: 0, col: 0)
//                }
//                //            case (.favoritesToggle, .up):
//                //                // from favorites <UP> to channels tab
//                //                withAnimation {
//                //                    focus = .tab(.channels)
//                //                }
//            case (.guide(_, let col), .left):
//                // from guide channel col <LEFT> to favorites
//                withAnimation {
//                    if col == 0 {
//                        focus = .favoritesToggle
//                    }
//                }
//                //            case (.guide(let row, _), .up):
//                //                // from guide at row 0, <UP> to favorites
//                //                withAnimation {
//                //                    if row == 0 {
//                //                        focus = .favoritesToggle
//                //                    }
//                //                }
//                
//            default:
//                break
//        }
        
        print("Focus set to: \(focus?.debugDescription ?? "unknown") <<<")
    }
#endif
}

#Preview {
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
                          url:"https://amg00793-amg00793c5-firetv-us-4068.playouts.now.amagi.tv/playlist.m3u8",
                          referrer: nil,
                          userAgent: nil,
                          quality: "2160p")
    
    
    let guideStore = GuideStore(streams: [stream], tunerChannels: [channel])
    
    ChannelsContainer().environment(guideStore)
        .ignoresSafeArea(.all)
}
