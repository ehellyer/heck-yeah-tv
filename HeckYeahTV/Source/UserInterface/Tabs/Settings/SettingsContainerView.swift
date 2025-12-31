//
//  SettingsContainerView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct SettingsContainerView: View {
    
    @Binding var appState: AppStateProvider
    
    var body: some View {
#if os(macOS)
        // On macOS, skip NavigationView entirely and use Form directly
        NavigationStack {
            SettingsView(appState: $appState)
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.clear)
        }
#else
        // iOS / tvOS
        NavigationStack {
            SettingsView(appState: $appState)
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
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return SettingsContainerView(appState: $appState)
        .modelContext(mockData.context)
}
