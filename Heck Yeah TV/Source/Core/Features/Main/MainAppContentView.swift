//
//  MainAppContentView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct MainAppContentView: View {
    
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
        // Alignment required to layout the play/pause button in the bottom left corner.
        ZStack(alignment: .bottomLeading)  {
            
            VLCPlayerView(isPlaying: isPlaying, selectedChannel: channel)
                .ignoresSafeArea(.all)
            
            if guideStore.isGuideVisible {
                TabContainerView()
                    .transition(.opacity)
            } else {
                TabActivationView()
            }
            
            if guideStore.isPlaying == false {
                PlaybackBadge(isPlaying: false)
                    .transition(.opacity)
                    .padding(.leading, 50)
                    .padding(.bottom, 50)
            }
            
            if guideStore.isPlaying && showPlayToast {
                PlaybackBadge(isPlaying: true)
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
#endif // os(tvOS)
        
#if os(macOS)
        // macOS: arrow keys re-show the guide
        .background( MacArrowKeyCatcher {
            withAnimation {
                guideStore.isGuideVisible = true
            }
        })
#endif // os(macOS)
    }
}



#if DEBUG && targetEnvironment(simulator)
private struct PreviewMainAppContentView: View {
    
    @FocusState var focus: FocusTarget?
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
            MainAppContentView().environment(guideStore)
        }
        .task {
            // This block runs when the view appears
            await guideStore.load(streams: [stream], tunerChannels: [channel])
        }
    }
}

#Preview {
    PreviewMainAppContentView()
        .ignoresSafeArea(.all)
}
#endif // DEBUG && targetEnvironment(simulator)
