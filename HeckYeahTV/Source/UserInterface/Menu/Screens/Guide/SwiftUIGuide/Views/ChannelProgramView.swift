//
//  ChannelProgramView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/1/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData


struct ChannelProgramView: View {
    
    @State var channelProgram: ChannelProgram
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @FocusState private var focusedButton: FocusedButton?
    
    private var isPlaying: Bool {
        let selectedChannelId = appState.selectedChannel
        return selectedChannelId != nil && selectedChannelId == channelProgram.channelId
    }
    
    private let cornerRadius: CGFloat = AppStyle.cornerRadius
    private var isProgramNow: Bool {
        let now = Date()
        return channelProgram.startTime <= now && channelProgram.endTime >= now
    }
    
    var body: some View {
        Button {
            withAnimation {
                appState.showProgramDetailCarousel = channelProgram
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(channelProgram.formattedTimeSlot)
                    .font(AppStyle.Fonts.programViewFont)
                    .foregroundColor(.guideForegroundNoFocus)
                
                Text(channelProgram.title)
                    .font(AppStyle.Fonts.programViewFont)
                    .foregroundColor(.guideForegroundNoFocus)
                    .lineLimit(2)
            }
            .padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
            .frame(height: AppStyle.ProgramView.height)
            .frame(width: AppStyle.ProgramView.width, alignment: .leading)
        }
        .focused($focusedButton, equals: .guide)
        .buttonStyle(FocusableButtonStyle(isPlaying: isPlaying,
                                          cornerRadius: cornerRadius,
                                          isFocused: focusedButton == .guide,
                                          isProgramNow: isProgramNow))
        .fixedSize(horizontal: true, vertical: true)
    }
}

#Preview("ChannelProgramView") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channelPrograms = swiftDataController.channelPrograms(for: channelId)
    
    return TVPreviewView() {
        
        VStack {
            if let channelProgram = channelPrograms.first {
                ChannelProgramView(channelProgram: channelProgram)
                    .onAppear {
                        appState.selectedChannel = channelId
                    }
            }
        }
    }
}
