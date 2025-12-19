//
//  CountryPickerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct CountryPickerView: View {
    
    let countries: [IPTVCountry]
    @Binding var selectedCountry: CountryCode
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchText = ""
    
    private var filteredCountries: [IPTVCountry] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredCountries, id: \.code) { country in
                    ListButtonRow(title: country.name,
                                  isSelected: selectedCountry == country.code) {
                        selectedCountry = country.code
                        dismiss()
                    }
                                  .id(country.code)
                }
            }
            
            .listStyle(.plain)
#if !os(tvOS)
            .scrollContentBackground(.hidden)
#endif
            .background(Color.clear)
            .preferredColorScheme(.dark)
            .toolbarColorScheme(.dark, for: .automatic)
            .foregroundStyle(.white)
            .tint(.white)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + settleTime) {
                    proxy.scrollTo(selectedCountry, anchor: .center)
                }
            }
            .searchable(text: $searchText,
                        placement: .automatic,
                        prompt: "Search countries")

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
    @Previewable @State var countryCode: CountryCode = "AL"
    let mockData = MockDataPersistence(appState: appState)
    
    let swiftDataController = MockSwiftDataController(viewContext: mockData.context,
                                                      selectedCountry: countryCode)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let countries = swiftDataController.countries()
    
    return ZStack {
        TVPreviewView() {
            NavigationStack {
                CountryPickerView(
                    countries: countries,
                    selectedCountry: Binding(
                        get: { swiftDataController.selectedCountry },
                        set: { swiftDataController.selectedCountry = $0 }
                    )
                )
            }
        }
    }
}
