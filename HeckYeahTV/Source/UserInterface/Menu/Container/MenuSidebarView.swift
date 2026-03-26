//
//  MenuSidebarView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 3/25/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

#if os(tvOS)
struct MenuSidebarView: View {
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
    private var selectedSection: Binding<AppSection> {
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
        NavigationSplitView {
            // Sidebar
            List(AppSection.allCases, selection: selectedSection) { section in
                NavigationLink(value: section) {
                    Label(section.title, systemImage: section.systemImage)
                }
            }
            .navigationTitle("Heck Yeah TV")
        } detail: {
            // Detail view based on selected section
            Group {
                switch appState.selectedTab {
                    case .playerControls:
                        PlayerOverlay()
                    case .recents:
                        RecentsView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    case .guide:
                        ChannelsContainer()
                            .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: 0)) // Expand on the left edge to prevent the clipping of the focus effect on the fav toggle view.
                    case .settings:
                        SettingsContainerView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color.clear)
        }
        .task {
            // Sanity check. PlayerOverlay is available on tvOS via sidebar.
            // Default to guide if no valid selection.
            if appState.selectedTab == .playerControls {
                // Player controls is valid on tvOS with sidebar
            }
        }
        .onExitCommand {
            // When user presses menu while in detail view, don't dismiss the entire menu
            // Let the system handle returning to sidebar
        }
    }
}

#Preview {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        MenuSidebarView()
    }
}
#endif
