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
        switch appState.selectedTab {
            case .guide:
                GuideView(appState: $appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                
            case .recents:
                RecentsView(appState: $appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            
            case .search:
                SearchView(appState: $appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)

            case .settings:
                SettingsContainerView(appState: $appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
        }
    }
}

#if !os(tvOS)
#Preview("SectionView") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    let mockData = MockDataPersistence(appState: appState)
    
    // Override the injected SwiftDataController
    let swiftController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftController
    
    //Select recent list tab
    appState.selectedTab = .recents
    
    // Loads up the recents list
    appState.selectedChannel = swiftController.guideChannelMap.map[1]
    appState.selectedChannel = swiftController.guideChannelMap.map[3]
    appState.selectedChannel = swiftController.guideChannelMap.map[5]
    appState.selectedChannel = swiftController.guideChannelMap.map[7]
    appState.selectedChannel = swiftController.guideChannelMap.map[9]
    appState.selectedChannel = swiftController.guideChannelMap.map[11]
    
    return SectionView(appState: $appState)
        .environment(\.modelContext, mockData.context)

}
#endif
