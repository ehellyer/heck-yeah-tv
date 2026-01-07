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
    
    @Query(sort: \Country.name, order: .forward) private var countries: [Country]
    @Query(sort: \ProgramCategory.name, order: .forward) private var categories: [ProgramCategory]
    
    private var selectedCountryName: String {
        let countryCode = swiftDataController.selectedCountry
        if let country = countries.first(where: { $0.code == countryCode }) {
            return country.name
        }
        return "None"
    }
    
    private var selectedCountryBinding: Binding<CountryCodeId> {
        Binding(
            get: { swiftDataController.selectedCountry },
            set: { swiftDataController.selectedCountry = $0 }
        )
    }
    
    private var selectedCategoryBinding: Binding<CategoryId?> {
        Binding(
            get: { swiftDataController.selectedCategory },
            set: { swiftDataController.selectedCategory = $0 }
        )
    }

    private var showFavoritesOnlyBinding: Binding<Bool> {
        Binding(
            get: { swiftDataController.showFavoritesOnly },
            set: { swiftDataController.showFavoritesOnly = $0 }
        )
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
                        selectedCountry: selectedCountryBinding
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
                        selectedCategory: selectedCategoryBinding
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
                
                // Favorite Filter Card
                Button {
                    showFavoritesOnlyBinding.wrappedValue.toggle()
                } label: {
                    Group {
                        HStack {
                            
                            Image(systemName: showFavoritesOnlyBinding.wrappedValue ? "star.fill" : "star")
                                .font(.title3)
                                .foregroundStyle(.yellow)
                                .padding(.leading, 10)
                            
                            VStack(alignment: .leading) {
                                Text("Favorites")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Show Favorites Only")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            Text(showFavoritesOnlyBinding.wrappedValue ? "On" : "Off")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .buttonStyle(FilterButtonStyle())
                
                // Count of channels matching criteria label.
                HStack {
                    Text("\(swiftDataController.channelBundleMap.map.count) channels in guide")
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
    
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context)
    InjectedValues[\.swiftDataController] = swiftDataController

    
    //Select recent list tab
    appState.selectedTab = .filter
    
    return TVPreviewView() {
        FilterView(appState: $appState)
            .modelContext(mockData.context)
    }
}
