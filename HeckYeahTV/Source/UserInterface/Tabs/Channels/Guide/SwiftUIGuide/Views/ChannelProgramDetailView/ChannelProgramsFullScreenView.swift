//
//  ChannelProgramsFullScreenView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/6/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelProgramsFullScreenView: View {
    
    @Binding var appState: AppStateProvider
    
    let channelPrograms: [ChannelProgram]
    @State var channel: Channel

    @State private var startOnProgram: ChannelProgramId
    @State private var scrollPositionId: Int?
    @State private var moveDirection: MoveDirection
    
    init(appState: Binding<AppStateProvider>,
         channelPrograms: [ChannelProgram],
         startOnProgram: ChannelProgramId,
         channel: Channel) {
        self._appState = appState
        self.channelPrograms = channelPrograms
        self._startOnProgram = State(initialValue: startOnProgram)
        self._channel = State(initialValue: channel)
        self._moveDirection = State(initialValue: .forward)
    }
    
    private enum MoveDirection {
        case forward
        case backward
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                
                Color.black
                    .ignoresSafeArea(edges: .all)
                
                VStack(alignment: .center, spacing: 0) {
                    HStack {
                        Spacer()
                        HStack(alignment: .center,
                               spacing: 4) {
                            
                            let logoWidth = AppStyle.ChannelView.logoSize.width
                            let logoHeight = AppStyle.ChannelView.logoSize.height
                            LoadImageAsync(url: channel.logoURL,
                                           defaultImage: Image(systemName: "tv.circle.fill"))
                            .frame(width: logoWidth, height: logoHeight)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(channel.title)
                                    .font(.title3.bold())
                                    .foregroundStyle(Color.guideForegroundNoFocus)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                ChannelViewSubTitle(channel: channel)
                            }
                        }
                        Spacer()

#if !os(tvOS)
                        Button {
                            withAnimation {
                                appState.showChannelProgramsFullScreen = nil
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

                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 40) {
                            ForEach(0..<channelPrograms.count, id: \.self) { index in
                                let channelProgram = channelPrograms[index]
                                ChannelProgramDetailView(channelProgram: channelProgram)
                                    .frame(width: reader.size.width)
                                    .padding(.top, 20)
                                    .id(index)
                            }
                        }
                        
                    }
                    .contentMargins(.horizontal, 0, for: .scrollContent)
                    .scrollTargetLayout()
                    .scrollTargetBehavior(.paging)
                    .scrollPosition(id: $scrollPositionId)
                }
                .focusable()
       
                .overlay(alignment: .bottom) {
                Spacer()
                    IndicatorView(totalCount: channelPrograms.count,
                                  currentIndex: $scrollPositionId)
                    .focusable()
                }
            }
            .onAppear {
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
                                moveDirection = .forward
                                scrollPositionId = (scrollPositionId ?? 0) + 1
                            }
                        case .right:
                            if scrollPositionId ?? 0 > 0 {
                                moveDirection = .backward
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
                    appState.showChannelProgramsFullScreen = nil
                }
            }
#endif
        }
        

        
    }
}

#Preview {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channel = try! swiftDataController.channel(for: channelId)
    let channelPrograms = swiftDataController.previewOnly_channelPrograms(channelId: channelId)
    
    //appState.selectedChannel = channelId
    return TVPreviewView() {
        
        VStack {
            ChannelProgramsFullScreenView(appState: $appState,
                                          channelPrograms: channelPrograms,
                                          startOnProgram: channelPrograms[15].id,
                                          channel: channel)
        }
    }
}
