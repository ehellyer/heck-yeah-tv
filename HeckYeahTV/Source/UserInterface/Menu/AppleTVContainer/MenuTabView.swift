//
//  MenuTabView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct MenuTabView: View {
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
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
                ChannelsContainer()
                    .padding(.leading, -20) // Expand on the left edge to prevent the clipping of the focus effect on the fav toggle view.
            }
            
            Tab(AppSection.recents.title,
                systemImage: AppSection.recents.systemImage,
                value: AppSection.recents) {
                RecentsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Tab(AppSection.filter.title,
                systemImage: AppSection.filter.systemImage,
                value: AppSection.filter) {
                FilterView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Tab(AppSection.settings.title,
                systemImage: AppSection.settings.systemImage,
                value: AppSection.settings) {
                SettingsContainerView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.clear)
        
        
        // Support for dismissing the tabview by tapping menu on Siri remote for tvOS.
        .onExitCommand {
            withAnimation {
                appState.showAppMenu = false
            }
        }
        
        .transition(
            .move(edge: .bottom)
            .combined(with: .opacity)
        )
    }
}

#if os(tvOS)
#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        MenuTabView()
    }
}
#endif
