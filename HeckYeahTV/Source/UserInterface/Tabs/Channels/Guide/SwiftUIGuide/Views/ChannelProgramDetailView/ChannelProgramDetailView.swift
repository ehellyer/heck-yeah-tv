//
//  ChannelProgramDetailView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/5/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ChannelProgramDetailView: View {

    @State var channelProgram: ChannelProgram
    
    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 10) {
                    
                    Text(channelProgram.title)
                        .font(.largeTitle)
                        .foregroundColor(.guideForegroundNoFocus)
                        .lineLimit(2)
                    
                    Text(channelProgram.formattedDayTimeSlot)
                        .font(AppStyle.Fonts.gridRowFont)
                        .foregroundColor(.guideForegroundNoFocus)

                    if let originalAirDate = channelProgram.formattedOriginalAirDate {
                        Text("Original air date: \(originalAirDate)")
                            .font(.caption)
                            .foregroundStyle(Color(.white))
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        if let episodeTitle = channelProgram.episodeTitle {
                            Text(episodeTitle)
                                .font(.title3)
                                .foregroundStyle(Color(.white))
                        }
                        
                        if let episodeNumber = channelProgram.episodeNumber {
                            Text(episodeNumber)
                                .font(.title3)
                                .foregroundStyle(Color(.white))
                        }
                    }
                    
                    if let synopsis = channelProgram.synopsis {
                        Text(synopsis)
                            .font(.body)
                            .foregroundStyle(Color(.white))
                    }
                    
                    if !channelProgram.filter.isEmpty {
                        HStack {
                            ForEach(channelProgram.filter, id: \.self) { filter in
                                Text(filter)
                                    .font(.caption)
                                    .padding(.trailing, 8)
                                    .padding(.vertical, 4)
                                    .foregroundStyle(.guideForegroundNoFocus)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
                if let url = channelProgram.programImageURL {
                    LoadImageAsync(url: url)
                        .tint(.guideForegroundNoFocus)
                        .foregroundColor(.guideForegroundNoFocus)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        
        .contentMargins(.bottom, 40, for: .scrollContent)
        .scrollClipDisabled()
    }
}


#Preview {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    
    let channelId = "7a9b1eebc340e54fd8e0383b3952863ba491fcb655c7bbdefa6ab2afd2e57dfd"
    let channelPrograms = swiftDataController.previewOnly_channelPrograms(channelId: channelId)
    
    //appState.selectedChannel = channelId
    return TVPreviewView() {
        
        VStack {
            if let channelProgram = channelPrograms.first {
                ChannelProgramDetailView(channelProgram: channelProgram)
                    .background(.black)
            }
        }
    }
}
