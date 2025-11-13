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
                        .background(Color.clear)
                case .recents:
                    RecentsView()
                case .search:
                    SearchView()
                case .settings:
                    SettingsView()
            }
        }
        .background(Color.clear)
    }
    
}

#if !os(tvOS)
#Preview("SectionView") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()

    let mockData = MockDataPersistence(appState: appState)
        
    SectionView(appState: $appState)
        .environment(\.modelContext, mockData.context)
        .environment(mockData.channelMap)
}
#endif
