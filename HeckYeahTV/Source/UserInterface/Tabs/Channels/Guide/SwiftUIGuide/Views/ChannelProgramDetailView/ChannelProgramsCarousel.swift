//
//  ChannelProgramsCarousel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/6/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelProgramsCarousel: View {
    
    @Binding var appState: AppStateProvider
    let channelPrograms: [ChannelProgram]
    @State var startOnProgram: ChannelProgramId?
    @State var channel: Channel

    @State private var scrollPositionId: Int?

    var body: some View {
        
        VStack(spacing: 0) {
            
            HStack {
                Spacer()
                ChannelName(channel: channel)
                Spacer()
#if !os(tvOS)
                Button {
                    withAnimation {
                        appState.showChannelPrograms = nil
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
            .padding(.bottom, 10)
            
            
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
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
            .tint(.white)
            .foregroundStyle(Color.white)
            .padding(.top, 10)
        }
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
                    case .left:
                        if scrollPositionId ?? 0 < channelPrograms.count - 1 {
                            scrollPositionId = (scrollPositionId ?? 0) + 1
                        }
                    case .right:
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
                appState.showChannelPrograms = nil
            }
        }
#endif
    }
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channel = try! swiftDataController.channel(for: channelId)
    let channelPrograms = swiftDataController.previewOnly_channelPrograms(channelId: channelId)

    //appState.selectedChannel = channelId
    return TVPreviewView() {
        
        VStack {
            ChannelProgramsCarousel(appState: $appState,
                                   channelPrograms: channelPrograms,
                                   startOnProgram: channelPrograms[8].id,
                                   channel: channel)
        }
    }
}
