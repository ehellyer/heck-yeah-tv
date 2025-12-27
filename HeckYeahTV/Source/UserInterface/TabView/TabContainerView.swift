//
//  TabContainerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct TabContainerView: View {
    
    @Binding var appState: AppStateProvider
    
    private var selectedTab: Binding<AppSection> {
        Binding(
            get: {
                appState.selectedTab
            },
            set: {
                appState.selectedTab = $0
            }
        )
    }
    
    var body: some View {
        TabView(selection: selectedTab) {
            
            Tab(AppSection.guide.title,
                systemImage: AppSection.guide.systemImage,
                value: AppSection.guide) {
                ChannelsContainer(appState: $appState)
                    .padding(.leading, -20) // Expand on the left edge to prevent the clipping of the focus effect on the fav toggle view.
            }
            
            Tab(AppSection.recents.title,
                systemImage: AppSection.recents.systemImage,
                value: AppSection.recents) {
                RecentsView(appState: $appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Tab(AppSection.filter.title,
                systemImage: AppSection.filter.systemImage,
                value: AppSection.filter) {
                FilterView(appState: $appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Tab(AppSection.settings.title,
                systemImage: AppSection.settings.systemImage,
                value: AppSection.settings) {
                SettingsContainerView(appState: $appState)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        
        
        // Support for dismissing the tabview by tapping menu on Siri remote for tvOS.
        .onExitCommand {
            withAnimation {
                appState.showAppNavigation = false
            }
        }
    }
}

#if os(tvOS)
#Preview {
    @Previewable @State var _appState: any AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockDataPersistence()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        TabContainerView(appState: $_appState)
            .modelContext(mockData.context)
    }
}
#endif
