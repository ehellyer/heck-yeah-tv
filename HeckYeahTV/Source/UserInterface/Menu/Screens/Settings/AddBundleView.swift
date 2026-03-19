//
//  AddBundleView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/23/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct AddBundleView: View {

    @Binding var navigationPath: [SettingsDestination]
    let onAdd: (ChannelBundle) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    @State private var bundleName = ""
    
#if os(tvOS)
    @FocusState private var isNameFieldFocused: Bool
#endif
    
    var body: some View {
        VStack(alignment: .leading) {
            Section {
                TextField("Bundle Name", text: $bundleName)
#if os(tvOS)
                    .focused($isNameFieldFocused)
#endif
                    .submitLabel(.done)
                    .onSubmit {
                        guard not(bundleName.trim().isEmpty) else {
                            return
                        }
                        if let newBundle = swiftDataController.addChannelBundle(name: bundleName) {
                            onAdd(newBundle)
                        }
                    }
            } header: {
                Text("New Channel Bundle")
            }

            Spacer()
        }
        .navigationTitle("Add Bundle")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif

#if os(tvOS)
        .onAppear {
            isNameFieldFocused = true
        }
#endif
    }
}

// MARK: - Preview

#Preview("Light Mode") {
    @Previewable @State var navigationPath: [SettingsDestination] = []
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        NavigationStack {
            AddBundleView(navigationPath: $navigationPath) { bundle in
                print(bundle.name)
            }
        }
        .background(.clear)
#if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        .containerBackground(.clear, for: .navigation)
#endif
    }
    .environment(\.colorScheme, .light)
}


#Preview("Dark Mode") {
    @Previewable @State var navigationPath: [SettingsDestination] = []
    // Override the injected AppStateProvider
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    return TVPreviewView() {
        NavigationStack {
            AddBundleView(navigationPath: $navigationPath) { bundle in
                print(bundle.name)
            }
        }
        .background(.clear)
#if os(iOS)
        .toolbarBackground(.hidden, for: .navigationBar)
        .containerBackground(.clear, for: .navigation)
#endif
    }
    .environment(\.colorScheme, .dark)
}

