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
    
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState
    
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

    @Namespace private var channelsScope

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TabView(selection: selectedTab) {
                
                Tab(TabSection.recents.title,
                    systemImage: TabSection.recents.systemImage,
                    value: TabSection.recents) {
                    RecentsView()
                }
                
                Tab(TabSection.channels.title,
                    systemImage: TabSection.channels.systemImage,
                    value: TabSection.channels) {
                    ChannelsContainer(focus: $focus, appState: $appState)
                        .focusScope(channelsScope)
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
            .padding(0)
            .background(Color.clear)
            .contentShape(Rectangle())                 // Make the whole rect focus-hit eligible
            
#if !os(iOS)
            // Support for dismissing the tabview by tapping menu on Siri remote for tvOS or esc key on keyboard (on tvOS or macOS).
            .onExitCommand {
                withAnimation {
                    appState.isGuideVisible = false
                }
            }
#endif
        }
        .frame(maxWidth: .infinity)                    // Ensure container also spans full width
    }
}
