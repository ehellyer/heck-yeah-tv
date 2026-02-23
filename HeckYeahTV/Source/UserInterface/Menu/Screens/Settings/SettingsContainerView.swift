//
//  SettingsContainerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

enum SettingsDestination: Hashable {
    case addBundle
    case bundleDetail(bundleId: String)
}

struct SettingsContainerView: View {
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    @State private var navigationPath: [SettingsDestination] = []
    
    var body: some View {
#if os(macOS)
        NavigationStack(path: $navigationPath) {
            SettingsView(navigationPath: $navigationPath)
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
        }
#elseif os(tvOS)
        NavigationStack(path: $navigationPath) {
            SettingsView(navigationPath: $navigationPath)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)
                    }
                }
        }
#elseif os(iOS)
        NavigationStack(path: $navigationPath) {
            SettingsView(navigationPath: $navigationPath)
        }
#endif
        
    }
}

// MARK: - Previews

#Preview("Light Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        SettingsContainerView()
            .environment(\.colorScheme, .light)
    }
}

#Preview("Dark Mode") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        SettingsContainerView()
            .environment(\.colorScheme, .dark)
    }
}

