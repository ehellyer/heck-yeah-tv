//
//  CountryPickerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct CountryPickerView: View {
    
    let countries: [Country]
    @Binding var selectedCountry: CountryCodeId
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchText = ""
    
    private var filteredCountries: [Country] {
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
                    ListButtonRow(emoji: country.flag,
                                  title: country.name,
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
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let countries = swiftDataController.previewOnly_countries()
    
    var selectedCountryBinding: Binding<CountryCodeId> {
        Binding(
            get: { swiftDataController.selectedCountry },
            set: { swiftDataController.selectedCountry = $0 }
        )
    }
    
    return ZStack {
        TVPreviewView() {
            NavigationStack {
                CountryPickerView(
                    countries: countries,
                    selectedCountry: selectedCountryBinding
                )
            }
        }
    }
}
