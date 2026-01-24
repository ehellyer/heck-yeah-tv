//
//  ProgramDetailText.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/19/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ProgramDetailText: View {
    
    @State var channelProgram: ChannelProgram
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            Text(channelProgram.title.trim())
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .font(.largeTitle)
                .foregroundColor(.guideForegroundNoFocus)
                .layoutPriority(1)
            
            Text(channelProgram.formattedDayTimeSlot)
                .font(AppStyle.Fonts.gridRowFont)
                .foregroundColor(.guideForegroundNoFocus)
            
            if let originalAirDate = channelProgram.formattedOriginalAirDate {
                Text("Original air date: \(originalAirDate)")
                    .font(AppStyle.Fonts.gridRowFont)
                    .foregroundStyle(Color.white)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                if let episodeTitle = channelProgram.episodeTitle?.nilIfEmpty() {
                    Text(episodeTitle.trim())
                        .font(.title3)
                        .foregroundStyle(Color.white)
                }
                
                if let episodeNumber = channelProgram.episodeNumber?.nilIfEmpty() {
                    Text(episodeNumber)
                        .font(.title3)
                        .foregroundStyle(Color.white)
                }
            }
            
            if let synopsis = channelProgram.synopsis?.nilIfEmpty() {
                Text(synopsis)
                    .multilineTextAlignment(.leading)
                    .font(.body)
                    .foregroundStyle(Color.white)
            }
            
            if !channelProgram.filter.isEmpty {
                HStack(spacing: 15) {
                    ForEach(channelProgram.filter, id: \.self) { filter in
                        Text(filter.trim())
                            .font(AppStyle.Fonts.gridRowFont)
                            .foregroundStyle(.guideForegroundNoFocus)
                    }
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channelPrograms = swiftDataController.previewOnly_channelPrograms(channelId: channelId)
    
    return TVPreviewView() {
        
        VStack {
            if let channelProgram = channelPrograms.first {
                ProgramDetailText(channelProgram: channelProgram)
            }
        }
    }
}
