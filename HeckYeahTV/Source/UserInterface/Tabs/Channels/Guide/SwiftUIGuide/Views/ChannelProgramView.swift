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
    
    @Binding var appState: AppStateProvider
    @State var channelProgram: ChannelProgram
    
    @FocusState private var focusedButton: FocusedButton?
    
    private var isPlaying: Bool {
        return appState.selectedChannel != nil && appState.selectedChannel == channelProgram.channelId
    }
    
    private let cornerRadius: CGFloat = AppStyle.cornerRadius
    private var isProgramNow: Bool {
        let now = Date()
        return channelProgram.startTime <= now && channelProgram.endTime >= now
    }
    
    var body: some View {
        Button {
            withAnimation {
                appState.showChannelProgramsFullScreen = channelProgram
            }
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(channelProgram.formattedTimeSlot)
                    .font(AppStyle.Fonts.gridRowFont)
                    .foregroundColor(.guideForegroundNoFocus)
                
                Text(channelProgram.title)
                    .font(AppStyle.Fonts.gridRowFont)
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
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channelPrograms = swiftDataController.previewOnly_channelPrograms(channelId: channelId)
    
    //appState.selectedChannel = channelId
    
    return TVPreviewView() {
        
        VStack {
            if let channelProgram = channelPrograms.first {
                ChannelProgramView(appState: $appState,
                                   channelProgram: channelProgram)
                .modelContext(mockData.viewContext)
            }
        }
    }
}
