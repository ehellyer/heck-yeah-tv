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
            VStack(spacing: 0) {
                // Filter Section Header
                VStack(alignment: .leading, spacing: 12) {
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
                        HStack {
                            Image(systemName: "globe")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                
                            
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
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
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
                        HStack {
                            Image(systemName: "square.grid.2x2")
                                .font(.title3)
                                .foregroundStyle(.purple)
                                
                            
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
                        .padding()
                        .background {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    // Results count
                    HStack {
                        Text("\(swiftDataController.guideChannelMap.map.count) channels")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)

                }
                .padding()
            }
            Spacer()
        }
    }
}

#Preview("FilterView") {
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    let mockData = MockDataPersistence(appState: appState)
    
    // Override the injected SwiftDataController
    let swiftController = MockSwiftDataController(viewContext: mockData.context,
                                                  selectedCountry: "US",
                                                  selectedCategory: nil,//"news",
                                                  showFavoritesOnly: false,
                                                  searchTerm: nil)//"Lo")
    
    InjectedValues[\.swiftDataController] = swiftController
    
    //Select recent list tab
    appState.selectedTab = .filter
    
    return FilterView(appState: $appState)
        .environment(\.modelContext, mockData.context)
}
