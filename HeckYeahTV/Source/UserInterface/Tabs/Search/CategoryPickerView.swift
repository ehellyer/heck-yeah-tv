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
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(categories, id: \.name) { category in
                    Button {
                        selectedCategory = category.categoryId
                        dismiss()
                    } label: {
                        HStack {
                            Text(category.name)
                            Spacer()
                            if selectedCategory == category.categoryId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(ListButtonStyle())
                    .id(category.categoryId)
#if !os(tvOS)
                    .listRowSeparator(.hidden)
#endif
                    .listRowBackground(Color.clear)
                }
            }
#if !os(tvOS)
            .scrollContentBackground(.hidden)
#endif
            .listStyle(.plain)
#if os(tvOS)
            .toolbarColorScheme(.dark)
            .foregroundStyle(.white)
            .foregroundColor(.white)
            .tint(.white)
            .accentColor(.white)
#endif
            
            .navigationTitle("Select a category")
            .onAppear {
                if let selectedCategory {
                    proxy.scrollTo(selectedCategory, anchor: .center)
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
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
//    let mockData = MockDataPersistence(appState: appState)
//    
//    return NavigationStack {
//        CategoryPickerView(
//            categories: mockData.categories,
//            selectedCategory: .constant("culture")
//        )
//    }
}
