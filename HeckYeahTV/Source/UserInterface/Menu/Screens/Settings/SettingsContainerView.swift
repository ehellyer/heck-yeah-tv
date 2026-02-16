//
//  SettingsContainerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct SettingsContainerView: View {
    
    @State private var appState: AppStateProvider = InjectedValues[\.sharedAppState]
    
    var body: some View {
#if os(macOS)
        NavigationStack {
            SettingsView()
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
        }
#elseif os(tvOS)
        NavigationStack {
            SettingsView()
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
        SettingsView()
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

