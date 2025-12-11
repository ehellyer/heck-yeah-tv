//
//  SearchView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct SearchView: View {
    
    @Binding var appState: AppStateProvider
    @Environment(\.modelContext) private var viewContext
    
    @Injected(\.swiftDataController) private var swiftDataController: SwiftDataControllable
    @Query(sort: \IPTVCountry.name, order: .forward) private var countries: [IPTVCountry]
    @Query(sort: \IPTVCategory.name, order: .forward) private var categories: [IPTVCategory]
    
    private var selectedCountryName: String {
        let countryCode = swiftDataController.selectedCountry
        if let country = countries.first(where: { $0.code == countryCode }) {
            return country.name
        }
        return "None"
    }
    
    private var selectedCategoryName: String {
        if let categoryCode = swiftDataController.selectedCategory,
           let category = categories.first(where: { $0.categoryId == categoryCode }) {
            return category.name
        }
        return "None"
    }
    
    var body: some View {
        NavigationStack {
            
            VStack {
                NavigationLink {
                    CountryPickerView(
                        countries: countries,
                        selectedCountry: Binding(
                            get: { swiftDataController.selectedCountry },
                            set: { swiftDataController.selectedCountry = $0 }
                        )
                    )
                } label: {
                    HStack {
                        Text("Select a country")
                        Spacer()
                        Text(selectedCountryName)
                    }
                    .modifier(SectionTextStyle())
                }
                
                
                NavigationLink {
                    CategoryPickerView(
                        categories: categories,
                        selectedCategory: Binding(
                            get: { swiftDataController.selectedCategory },
                            set: { swiftDataController.selectedCategory = $0 }
                        )
                    )
                } label: {
                    HStack {
                        Text("Select a category")
                        Spacer()
                        Text(selectedCategoryName)
                    }
                    .modifier(SectionTextStyle())
                }
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            ForEach(appState.recentChannelIds, id: \.self) { channelId in
                                GuideRowLazy(channelId: channelId,
                                             appState: $appState,
                                             hideGuideInfo: true)
                                .id(channelId)
                                .padding(.leading, 5)
                                .padding(.trailing, 5)
                            }
                            if appState.recentChannelIds.isEmpty {
                                Text("No channels match criteria.")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .focusable(false)
                            }
                        }
                    }
                    .background(.clear)
                    .scrollClipDisabled(true)
                    .contentMargins(.top, 5)
                    .contentMargins(.bottom, 5)
                }
            }
        }
        
    }
}

#Preview("SearchView") {
//    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
//    let mockData = MockDataPersistence(appState: appState)
//    appState.selectedChannel = mockData.channels[0].id
//    appState.selectedChannel = mockData.channels[1].id
//    appState.selectedChannel = mockData.channels[2].id
//    appState.selectedChannel = mockData.channels[3].id
//    appState.selectedChannel = mockData.channels[4].id
//    
//
//    
//    return SearchView(appState: $appState)
//        .environment(\.modelContext, mockData.context)
//        .environment(mockData.channelMap)
}
