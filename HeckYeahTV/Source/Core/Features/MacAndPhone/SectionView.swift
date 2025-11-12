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
    @State private var scrollToSelected: Bool = true
    
    var body: some View {
        SectionContentView() {
            
            switch appState.selectedTab {
                case .channels:
                    GuideView(appState: $appState,
                              scrollToSelected: $scrollToSelected)
                case .recents:
                    RecentsView()
                case .search:
                    SearchView()
                case .settings:
                    SettingsView()
            }
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Picker("Category", selection: $appState.selectedTab) {
                        ForEach(TabSection.allCases) { tabSection in
                            Text(tabSection.title).tag(tabSection)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    Toggle(isOn: $appState.showFavoritesOnly) {
                        Label("Favorites only", systemImage: "star.fill")
                    }
                    
                } label: {
                    Label("Filter", systemImage: "slider.horizontal.3")
                }
            }
        }
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
