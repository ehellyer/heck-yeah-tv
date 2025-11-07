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
    
    private var selectedTab: Binding<TabSection> {
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
        VStack(alignment: .leading, spacing: 0) {
            TabView(selection: selectedTab) {
                
                Tab(TabSection.channels.title,
                    systemImage: TabSection.channels.systemImage,
                    value: TabSection.channels) {
                    ChannelsContainer(appState: $appState)
                        .padding(.leading, -20) // Expand on the left edge to prevent the clipping of the focus effect on the fav toggle view.
                }

                Tab(TabSection.recents.title,
                    systemImage: TabSection.recents.systemImage,
                    value: TabSection.recents) {
                    RecentsView()
                }
                
                Tab(TabSection.search.title,
                    systemImage: TabSection.search.systemImage,
                    value: TabSection.search) {
                    SearchView()
                }
                
                Tab(TabSection.settings.title,
                    systemImage: TabSection.settings.systemImage,
                    value: TabSection.settings) {
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity)                // Expand TabView to full width
            
            .background(Color.clear)
            
            // Support for dismissing the tabview by tapping menu on Siri remote for tvOS.
            .onExitCommand {
                withAnimation {
                    appState.isGuideVisible = false
                }
            }
        }
        .frame(maxWidth: .infinity)                    // Ensure container also spans full width
    }
}
