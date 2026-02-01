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
                GuideView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                
            case .recents:
                RecentsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
            
            case .filter:
                FilterView(appState: $appState)
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
   
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    //Select recent list tab
    appState.selectedTab = .recents
    
    return TVPreviewView() {
        SectionView(appState: $appState)
            .environment(\.modelContext, swiftDataController.viewContext)
            .onAppear() {
                    // Loads up the recents list
//                    appState.selectedBundleChannel = swiftDataController.channelBundleMap.map[1]
//                    appState.selectedBundleChannel = swiftDataController.channelBundleMap.map[3]
//                    appState.selectedBundleChannel = swiftDataController.channelBundleMap.map[5]
//                    appState.selectedBundleChannel = swiftDataController.channelBundleMap.map[7]
//                    appState.selectedBundleChannel = swiftDataController.channelBundleMap.map[9]
//                    appState.selectedBundleChannel = swiftDataController.channelBundleMap.map[11]
            }
    }
}
#endif
