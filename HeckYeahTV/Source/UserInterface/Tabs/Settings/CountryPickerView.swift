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
    @Binding var selectedCountry: CountryCode?
    @Environment(\.dismiss) private var dismiss
    
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
                    Button {
                        selectedCountry = country.code
                        dismiss()
                    } label: {
                        HStack {
                            Text(country.name)
                            Spacer()
                            if selectedCountry == country.code {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .buttonStyle(ListButtonStyle())
                    .id(country.code)
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

            .searchable(text: $searchText, placement: .automatic, prompt: "Search countries")
#if os(tvOS)
            .toolbarColorScheme(.dark)
            .foregroundStyle(.white)
            .foregroundColor(.white)
            .tint(.white)
            .accentColor(.white)
#endif
            
            .navigationTitle("Select a country")
            .onAppear {
                if let selectedCountry {
                    proxy.scrollTo(selectedCountry, anchor: .center)
                }
            }
            .onChange(of: searchText) { oldValue, newValue in
                // Scroll to selected item when search is cleared
                if newValue.isEmpty, let selectedCountry {
                    withAnimation {
                        proxy.scrollTo(selectedCountry, anchor: .center)
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
    @Previewable @State var appState: any AppStateProvider = MockSharedAppState()
    
    appState.selectedCountry = "US"

//    UISearchBar.appearance().tintColor = .white
//    UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = .white
//    UITextField.appearance().textColor = .white
//    UITextField.appearance().tintColor = .white
    
    let mockData = MockDataPersistence(appState: appState)
    
    return NavigationStack {
        CountryPickerView(
            countries: mockData.countries,
            selectedCountry: .constant("US")
        )
    }
}
