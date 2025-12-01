//
//  SectionView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/6/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct SectionView: View {
    
    @Binding var appState: AppStateProvider
    
    var body: some View {
        SectionContentView() {
            
            switch appState.selectedTab {
                case .channels:
                    GuideView(appState: $appState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                    
                case .recents:
                    RecentsView(appState: $appState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
                    
                case .settings:
                    SettingsContainerView(appState: $appState)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.clear)
            }
        }
        .background(Color.clear)
    }
}

#if !os(tvOS)
#Preview("SectionView") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    let mockData = MockDataPersistence(appState: appState)
    // Loads up the recents list
    appState.selectedChannel = mockData.channels[1].id
    appState.selectedChannel = mockData.channels[3].id
    appState.selectedChannel = mockData.channels[5].id
    appState.selectedChannel = mockData.channels[7].id
    appState.selectedChannel = mockData.channels[9].id
    appState.selectedTab = .recents
    
    return SectionView(appState: $appState)
        .environment(\.modelContext, mockData.context)
        .environment(mockData.channelMap)
}
#endif
