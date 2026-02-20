//
//  CountryPickerView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/8/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct CountryPickerView: View {
    @Binding var selectedCountry: CountryCodeId
    let countries: [Country]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                ForEach(countries, id: \.code) { country in
                    Button {
                        selectedCountry = country.code
                        dismiss()
                    } label: {
                        HStack {
                            Text("\(country.flag) \(country.name)")
                            Spacer()
                            if selectedCountry == country.code {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Select Country")
            } footer: {
                Text("Choose a country to filter available channels.")
            }
        }
        .navigationTitle("Country")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

#Preview {
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let countries = swiftDataController.countries()
    
    return TVPreviewView() {
        NavigationStack {
            CountryPickerView(
                selectedCountry: .constant("US"),
                countries: countries
            )
        }
    }
}
