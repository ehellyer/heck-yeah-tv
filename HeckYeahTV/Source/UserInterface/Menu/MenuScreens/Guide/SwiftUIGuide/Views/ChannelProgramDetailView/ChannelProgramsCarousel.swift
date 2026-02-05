//
//  ChannelProgramsCarousel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/6/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelProgramsCarousel: View {
    
    let channelPrograms: [ChannelProgram]
    @State var startOnProgram: ChannelProgramId?
    @State var channel: Channel

    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var scrollPositionId: Int?

    var body: some View {
        
        VStack(spacing: 0) {
            
            HStack {
                Spacer()
                ChannelName(channel: channel)
                    .foregroundStyle(.white)
                Spacer()
#if !os(tvOS)
                Button {
                    withAnimation {
                        appState.showProgramDetailCarousel = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
                .padding()
#endif
            }
            .padding(.bottom, AppStyle.ProgramCarousel.channelNameBottomPadding)
            
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(0..<channelPrograms.count, id: \.self) { index in
                            let padding = max(20, ((proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing) / 2))
                            let channelProgram = channelPrograms[index]
                            
                            ProgramDetailView(channelProgram: channelProgram)
                                .padding(.leading, padding)
                                .padding(.trailing, padding)
                                .containerRelativeFrame(.horizontal)
                                .id(index)
                                .scrollTransition(.animated) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1 : 0.0)
                                }
                        }
                    }
                }
                .scrollTargetLayout()
                .scrollTargetBehavior(.paging)
                .ignoresSafeArea(.all)
                .scrollPosition(id: $scrollPositionId)
            }
            
            PageControlView(numberOfPages: channelPrograms.count,
                            activePage: scrollPositionId,
                            onPageChange: { index in
                scrollPositionId = index
            })
            .fixedSize(horizontal: false, vertical: true)
            .tint(.white)
            .foregroundStyle(Color.white)
            .padding(.top, 10)
#if os(macOS)
            .padding(.bottom, 10)
#endif
        }
        .frame(maxHeight: .infinity)
        .background(.black.opacity(0.9))
        .focusable()
        .onAppear() {
            let initialIndex = channelPrograms.firstIndex(where: {
                $0.id == startOnProgram
            })
            self.scrollPositionId = initialIndex
        }
#if os(tvOS)
        .onMoveCommand { direction in
            withAnimation {
                switch direction {
                    case .right:
                        if scrollPositionId ?? 0 < channelPrograms.count - 1 {
                            scrollPositionId = (scrollPositionId ?? 0) + 1
                        }
                    case .left:
                        if scrollPositionId ?? 0 > 0 {
                            scrollPositionId = (scrollPositionId ?? 0) - 1
                        }
                    default:
                        break
                }
            }
        }
        
        // Support for dismissing the tabview by tapping menu on Siri remote for tvOS.
        .onExitCommand {
            withAnimation {
                appState.showProgramDetailCarousel = nil
            }
        }
#endif
    }
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channel = try! swiftDataController.channel(for: channelId)
    let channelPrograms = swiftDataController.channelPrograms(for: channelId)

    //appState.selectedBundleChannel = channelId
    return TVPreviewView() {
        
        VStack {
            ChannelProgramsCarousel(channelPrograms: channelPrograms,
                                    startOnProgram: channelPrograms[8].id,
                                    channel: channel)
        }
    }
}
