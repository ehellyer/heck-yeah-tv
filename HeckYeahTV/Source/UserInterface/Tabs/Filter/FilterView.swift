//
//  FilterView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct FilterView: View {
    
    @Binding var appState: AppStateProvider
    @Environment(\.modelContext) private var viewContext
    @State private var swiftDataController: SwiftDataControllable = InjectedValues[\.swiftDataController]
    
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
            
            VStack(alignment: .leading, spacing: 20) {
                
                // Country Filter Card
                NavigationLink {
                    CountryPickerView(
                        countries: countries,
                        selectedCountry: Binding(
                            get: { swiftDataController.selectedCountry },
                            set: { swiftDataController.selectedCountry = $0 }
                        )
                    )
                } label: {
                    Group {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .padding(.leading, 10)
                            
                            VStack(alignment: .leading) {
                                Text("Country")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(selectedCountryName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(FilterButtonStyle())
                
                
                // Category Filter Card
                NavigationLink {
                    CategoryPickerView(
                        categories: categories,
                        selectedCategory: Binding(
                            get: { swiftDataController.selectedCategory },
                            set: { swiftDataController.selectedCategory = $0 }
                        )
                    )
                } label: {
                    Group {
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .font(.title3)
                                .foregroundStyle(.purple)
                                .padding(.leading, 10)
                            
                            VStack(alignment: .leading) {
                                Text("Category")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text(selectedCategoryName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.secondary)
                        }
                    }
                }
                .buttonStyle(FilterButtonStyle())
                
                // Results count
                HStack {
                    Text("\(swiftDataController.guideChannelMap.map.count) channels in guide")
                        .font(.caption)
#if os(tvOS)
                        .foregroundStyle(.white)
#else
                        .foregroundStyle(.secondary)
#endif
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .padding()
            Spacer()
        }
    }
}

#Preview("FilterView") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    let mockData = MockDataPersistence(appState: appState)
    
    @FocusState var categoryFocused: Bool
    
    
    // Override the injected SwiftDataController
    let swiftController = MockSwiftDataController(viewContext: mockData.context,
                                                  selectedCountry: "US",
                                                  selectedCategory: nil,//"news",
                                                  showFavoritesOnly: false,
                                                  searchTerm: nil)//"Lo")
    
    InjectedValues[\.swiftDataController] = swiftController
    
    //Select recent list tab
    appState.selectedTab = .filter
    
    return TVPreviewView() {
        FilterView(appState: $appState)
            .modelContext(mockData.context)
            .onAppear {
                // Trigger focus on first button
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    
                }
            }
    }
}
