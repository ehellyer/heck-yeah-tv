//
//  AddBundleView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/23/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct AddBundleView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var swiftDataController: SwiftDataProvider = InjectedValues[\.swiftDataController]
    @State private var bundleName = ""
    @Binding var navigationPath: [SettingsDestination]
    let onAdd: (ChannelBundle) -> Void
    
#if os(tvOS)
    @FocusState private var isNameFieldFocused: Bool
#endif
    
    var body: some View {
        Form {
            Section {
                TextField("Bundle Name", text: $bundleName)
#if os(tvOS)
                    .focused($isNameFieldFocused)
#endif
            } header: {
                Text("New Channel Bundle")
            }
        }
        .navigationTitle("Add Bundle")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    if let newBundle = swiftDataController.addChannelBundle(name: bundleName) {
                        onAdd(newBundle)
                    }
                }
                .disabled(bundleName.trim().isEmpty)
            }
        }
#if os(tvOS)
        .onAppear {
            isNameFieldFocused = true
        }
#endif
    }
}
