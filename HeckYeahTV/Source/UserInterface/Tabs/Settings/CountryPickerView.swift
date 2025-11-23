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
    
    var body: some View {
        List {
            Button {
                selectedCountry = nil
                dismiss()
            } label: {
                HStack {
                    Text("None")
                    Spacer()
                    if selectedCountry == nil {
                        Image(systemName: "checkmark")
                            
                    }
                }
            }
            .buttonStyle(TVButtonStyle())
            
            ForEach(countries, id: \.code) { country in
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
                .buttonStyle(TVButtonStyle())
            }
        }
        .navigationTitle("Select a country")
    }
}
