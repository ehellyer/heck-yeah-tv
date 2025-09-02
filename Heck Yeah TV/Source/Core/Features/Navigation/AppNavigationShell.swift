//
//  AppNavigationShell.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

// MARK: - Root Shell: picks the right container per platform

struct AppNavigationShell: View {
    @State private var selectedTab: TabSection = .last
    
    var body: some View {
#if os(tvOS)
        TVTabViewNavigation(selection: $selectedTab) {
            contentView(for: selectedTab)
        }
        .background(Color.black.opacity(0.9).ignoresSafeArea())
        
#elseif os(iOS)
        Group {
            TabBarNavigation(selection: $selectedTab) {
                contentView(for: selectedTab)
            }
        }
#elseif os(macOS)
        SidebarNavigation(selection: $selectedTab) {
            contentView(for: selectedTab)
        }
#endif
    }
    
    @ViewBuilder
    private func contentView(for section: TabSection) -> some View {
        switch section {
            case .last:     LastChannelView()
            case .recents:  RecentsView()
            case .channels: ChannelsView()
            case .search:   SearchView()
            case .settings: SettingsView()
        }
    }
}

// MARK: - Previews

#Preview("Adaptive Container") {
    AppNavigationShell()
}

