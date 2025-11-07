//
//  PhoneGuideView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/6/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct PhoneGuideView: View {
    
    @Binding var appState: AppStateProvider
    @Binding var scrollToSelected: Bool
    
    var body: some View {
        NavigationView {
            GuideView(appState: $appState, scrollToSelected: $scrollToSelected)
                .navigationTitle(Text("Channels"))
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
}

#if !os(tvOS)
#Preview("PhoneGuideView") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState(showFavoritesOnly: false)
    @Previewable @State var scrollToSelected = false

    let mockData = MockDataPersistence(appState: appState)
        
    PhoneGuideView(appState: $appState, scrollToSelected: $scrollToSelected)
        .environment(\.modelContext, mockData.context)
        .environment(mockData.channelMap)
}
#endif
