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
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
    var body: some View {
        switch appState.selectedTab {
            case .guide:
                GuideView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                
            case .recents:
                RecentsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            
            case .filter:
                FilterView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)

            case .settings:
                SettingsContainerView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
        }
    }
}

#if !os(tvOS)
#Preview("SectionView") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    //Select recent list tab
    appState.selectedTab = .recents
    
    return TVPreviewView() {
        SectionView()
            .onAppear() {
                    // Loads up the recents list
                    appState.selectedChannel = swiftDataController.channelBundleMap.map[1].channelId
                    appState.selectedChannel = swiftDataController.channelBundleMap.map[3].channelId
                    appState.selectedChannel = swiftDataController.channelBundleMap.map[5].channelId
                    appState.selectedChannel = swiftDataController.channelBundleMap.map[7].channelId
                    appState.selectedChannel = swiftDataController.channelBundleMap.map[9].channelId
                    appState.selectedChannel = swiftDataController.channelBundleMap.map[11].channelId
            }
    }
}
#endif
