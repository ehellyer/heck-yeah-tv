//
//  ProgramDetailView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/5/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct ProgramDetailView: View {
    
    @State var channelProgram: ChannelProgram
    
    var body: some View {
        ScrollView {
            Group {
                HStack(alignment: .top, spacing: 10) {
                    ProgramDetailText(channelProgram: channelProgram)
                        .layoutPriority(1)
                        .frame(maxWidth: .infinity)
                    
                    if let url = channelProgram.programImageURL {
                        LoadImageAsync(url: url)
                            .layoutPriority(0)
                            .frame(maxWidth: .infinity)
                            .tint(.guideForegroundNoFocus)
                            .foregroundColor(.guideForegroundNoFocus)
                            .cornerRadius(15)
                    }
                }
            }
        }
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
    let channelPrograms = swiftDataController.channelPrograms(for: channelId)
    
    //appState.selectedBundleChannel = channelId
    return TVPreviewView() {
        
        VStack {
//            ProgramDetailView(channelProgram: channelPrograms[0])
            ProgramDetailView(channelProgram: channelPrograms[0])
        }
    }
}
