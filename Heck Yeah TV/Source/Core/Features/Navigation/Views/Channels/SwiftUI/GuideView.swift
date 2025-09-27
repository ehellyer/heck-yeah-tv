//
//  GuideView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct GuideView: View {
    
    private let corner: CGFloat = 14
    
    @Environment(GuideStore.self) var guideStore
    @FocusState.Binding var focus: FocusTarget?
    @State private var onAppearTask: Task<Void, Never>? = nil
    
    private var onAppearTarget: FocusTarget {
        if let channelId = guideStore.selectedChannel?.id {
            return .guide(channelId: channelId, col: 0)
        } else {
            return .favoritesToggle
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            
            ScrollView (.vertical) {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(guideStore.channels) { channel in
                        GuideRow(channel: channel, focus: $focus)
                            .id(channel.id)
                    }
                }
                .padding(.vertical, 0)
                
            }
            .scrollClipDisabled()
            .background(Color.clear)
            .onAppear {
                if let channelId = guideStore.selectedChannel?.id {
                    onAppearTask = Task { @MainActor in
                        withAnimation(.easeOut) {
                            proxy.scrollTo(channelId, anchor: .center)
                        }
                        
                        do {
                            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
                            try Task.checkCancellation( )
                            withAnimation(.easeOut) {
                                guideStore.selectedTab = TabSection.channels
                                focus = onAppearTarget
                            }
                        } catch {
                            // Task Cancelled - no op.
                            print("Guide View onAppear focus set task cancelled.")
                        }
                    }
                }
            }
            .onChange(of: guideStore.selectedTab) { _, new in
                if new != TabSection.channels {
                    onAppearTask?.cancel()
                }
            }
            
            .onChange(of: focus) { _, new in
                if case let .guide(id, _) = new {
                    withAnimation(.easeOut) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        
        .background(Color.clear)
    }
}

#if DEBUG && targetEnvironment(simulator)
private struct PreviewGuideView: View {
    
    @FocusState private var focus: FocusTarget?
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
            GuideView(focus: $focus).environment(guideStore)
        }
        .task {
            // This block runs when the view appears
            await guideStore.load(streams: [stream], tunerChannels: [channel])
        }
    }
}

#Preview {
    PreviewGuideView()
        .ignoresSafeArea(.all)
}
#endif // DEBUG && targetEnvironment(simulator)
