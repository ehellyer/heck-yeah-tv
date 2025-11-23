//
//  SettingsView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    @Binding var appState: AppStateProvider
    
    var body: some View {
#if os(macOS)
        // On macOS, skip NavigationView entirely and use Form directly
        SettingsFormContent(appState: $appState)
            .formStyle(.grouped)
            .scrollContentBackground(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.clear)
#else
        // iOS / tvOS
        NavigationStack {
            SettingsFormContent(appState: $appState)
                .navigationTitle(Text("Settings"))
        }
#endif
    }
}

// MARK: - Previews

#Preview("SettingsView") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    let mockData = MockDataPersistence(appState: appState)
    
    return SettingsView(appState: $appState)
        .environment(\.modelContext, mockData.context)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
}
