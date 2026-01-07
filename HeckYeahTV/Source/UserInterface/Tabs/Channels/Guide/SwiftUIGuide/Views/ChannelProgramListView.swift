//
//  ChannelProgramListView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/1/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct ChannelProgramListView: View {
    
    @Binding var appState: AppStateProvider
    @State var channelId: ChannelId
    
    @Environment(\.modelContext) private var viewContext
    @StateObject private var loader = ProgramsRowLoader()
    @State private var scrollToProgramId: ChannelProgramId?
    
    private var isPlaying: Bool {
        return appState.selectedChannel == channelId
    }
    
    var body: some View {
        let programs: [ChannelProgram] = loader.programs ?? []
        
        ZStack {
            if programs.count == 0 {
                NoChannelProgramView(appState: $appState,
                                     channelId: channelId)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(alignment: .center,
                               spacing: AppStyle.ProgramView.programSpacing) {
                        ForEach(programs, id: \.id) { program in
                            ChannelProgramView(appState: $appState,
                                               channelProgram: program)
                            .layoutPriority(1)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrollToProgramId, anchor: .leading)
            }
        }
        .modifier(RedactedIfNeeded(type: programs))
        .onChange(of: programs) { _, newValue in
            scrollToCurrentProgram(programs: newValue)
        }
        .onAppear {
            loader.load(channelId: channelId, context: viewContext)
        }
        .onDisappear {
            loader.cancel()
        }

    }
    
    // MARK: - Helper Methods
    
    /// Scrolls to the program with the nearest time slot to now
    /// - If a program is currently airing, scroll to it
    /// - If all programs are in the future, scroll to the first (soonest) program
    /// - If all programs are in the past, scroll to the last (most recent) program
    private func scrollToCurrentProgram(programs: [ChannelProgram]) {
        guard !programs.isEmpty else { return }
        
        let now = Date()
        
        // Case 1: Check if there's a program currently airing
        if let currentProgram = programs.first(where: { prg in
            prg.startTime <= now && prg.endTime >= now
        }) {
            scrollToProgramId = currentProgram.id
            return
        }
        
        // Case 2: All programs are in the future, find the first one
        if let firstFutureProgram = programs.first(where: { prg in
            prg.startTime > now
        }) {
            scrollToProgramId = firstFutureProgram.id
            return
        }
        
        // Case 3: All programs are in the past, get the last one (most recent)
        if let lastPastProgram = programs.last {
            scrollToProgramId = lastPastProgram.id
        }
    }
}

#Preview {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channelId = swiftDataController.channelBundleMap.map[1]
    
    //appState.selectedChannel = channelId
    
    return TVPreviewView() {
        ChannelProgramListView(appState: $appState,
                               channelId: channelId)
        .modelContext(mockData.context)
    }
    
}


