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
    @FocusState private var focusedCategory: String?
    
    var body: some View {
        ScrollViewReader { proxy in
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
                        .foregroundStyle(.primary)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .id("all_categories")
                    .focused($focusedCategory, equals: "all_categories")
                    
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
                            .foregroundStyle(.primary)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(category.categoryId)
                        .focused($focusedCategory, equals: category.categoryId)
                    }
                } header: {
                    Text("Select Category")
                        .foregroundStyle(.white)
                } footer: {
                    Text("Choose a category to filter available channels, or select 'All Categories' to show all.")
                        .foregroundStyle(.white)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let targetId = selectedCategory ?? "all_categories"
                    proxy.scrollTo(targetId, anchor: .center)
#if os(tvOS)
                    focusedCategory = targetId
#endif
                }
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
