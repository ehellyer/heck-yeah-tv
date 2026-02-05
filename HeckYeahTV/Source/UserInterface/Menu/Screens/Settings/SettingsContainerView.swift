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
        // On macOS, skip NavigationView entirely and use Form directly
        NavigationStack {
            SettingsView()
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
        }
#else
        // iOS / tvOS
        NavigationStack {
            SettingsView()
#if os(tvOS)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.white)
                    }
                }
#endif
        }
#endif
    }
}

// MARK: - Previews

#Preview("SettingsContainerView") {
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return SettingsContainerView()
}
