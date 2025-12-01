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
    appState.selectedCountry = "US"
    
    let mockData = MockDataPersistence(appState: appState)
    
    return SettingsContainerView(appState: $appState)
        .environment(\.modelContext, mockData.context)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
