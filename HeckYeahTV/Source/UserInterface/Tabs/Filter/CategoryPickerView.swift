//
//  CategoryPickerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct CategoryPickerView: View {
    
    let categories: [IPTVCategory]
    @Binding var selectedCategory: CategoryId?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ListButtonRow(title: "None",
                              isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                    dismiss()
                }.id("none-option")
                
                ForEach(categories, id: \.name) { category in
                    ListButtonRow(title: category.name,
                                  isSelected: selectedCategory == category.categoryId) {
                        selectedCategory = category.categoryId
                        dismiss()
                    }.id(category.categoryId)
                }
            }
            .listStyle(.plain)
#if !os(tvOS)
            .scrollContentBackground(.hidden)
#endif
            .background(Color.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Select Category")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor({
#if os(tvOS)
                            return .white
#else
                            return colorScheme == .dark ? .white : .black
#endif
                        }())
                }
            }
            .toolbarColorScheme(.dark, for: .automatic)
            .toolbarTitleDisplayMode(.inline)
            .preferredColorScheme(.dark)
            .onAppear {
                if let selectedCategory {
                    DispatchQueue.main.asyncAfter(deadline: .now() + settleTime) {
                        proxy.scrollTo(selectedCategory, anchor: .center)
                    }
                }
            }
#if os(tvOS)
            .onExitCommand {
                dismiss()
            }
#endif
        }
    }
}


#Preview {
    @Previewable @State var appState: AppStateProvider = MockSharedAppState()
    @Previewable @State var categoryId: CategoryId? = "auto"
    let mockData = MockDataPersistence(appState: appState)
    
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context,
                                                      selectedCategory: categoryId!)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let categories = swiftDataController.categories()
    
    return ZStack {
        TVPreviewView() {
            NavigationStack {
                CategoryPickerView(
                    categories: categories,
                    selectedCategory: Binding(
                        get: { swiftDataController.selectedCategory },
                        set: { swiftDataController.selectedCategory = $0 }
                    )
                )
            }
        }
    }
}
