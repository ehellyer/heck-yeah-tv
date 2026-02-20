//
//  CategoryPickerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/8/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selectedCategory: CategoryId?
    let categories: [ProgramCategory]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                Button {
                    selectedCategory = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("All Categories")
                        Spacer()
                        if selectedCategory == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                ForEach(categories, id: \.categoryId) { category in
                    Button {
                        selectedCategory = category.categoryId
                        dismiss()
                    } label: {
                        HStack {
                            Text(category.name)
                            Spacer()
                            if selectedCategory == category.categoryId {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Select Category")
            } footer: {
                Text("Choose a category to filter available channels, or select 'All Categories' to show all.")
            }
        }
        .navigationTitle("Category")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

// MARK: - Preview

#Preview {
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let categories = swiftDataController.programCategories()
    
    return TVPreviewView() {
        NavigationStack {
            CategoryPickerView(
                selectedCategory: .constant(nil),
                categories: categories
            )
        }
    }
}
