//
//  BundleNameEditView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/14/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

/// A dedicated screen for editing bundle names on tvOS with improved text input UX
struct BundleNameEditView: View {
    
    @Binding var bundleName: String
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedName: String = ""
    @State private var showingEmptyNameAlert = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            
            Text("Edit Bundle Name")
                .font(.title2)
                .bold()
            
            TextField("Bundle Name", text: $editedName)
#if !os(tvOS)
                .textFieldStyle(.roundedBorder)
#endif
                .focused($isTextFieldFocused)
#if os(tvOS)
                .font(.title3)
                .padding(.horizontal, 100)
#else
                .font(.body)
                .padding(.horizontal, 20)
#endif
            
            HStack(spacing: 40) {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    saveName()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Preview: \(editedName.trimmingCharacters(in: .whitespacesAndNewlines))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear {
            editedName = bundleName
            isTextFieldFocused = true
        }
        .alert("Bundle Name Required", isPresented: $showingEmptyNameAlert) {
            Button("OK", role: .cancel) {
                isTextFieldFocused = true
            }
        } message: {
            Text("The bundle name cannot be empty or only whitespace.")
        }
    }
    
    // MARK: - Actions
    
    private func saveName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            showingEmptyNameAlert = true
        } else {
            bundleName = trimmed
            dismiss()
        }
    }
}

// MARK: - Previews

#Preview("tvOS") {
    @Previewable @State var bundleName = "My Bundle"
    
    NavigationStack {
        BundleNameEditView(bundleName: $bundleName)
    }
}
