//
//  SettingsFormContent.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

struct SettingsFormContent: View {
    @Binding var appState: AppStateProvider
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var showingCountryPicker = false
    
    private var filteredCountries: [IPTVCountry] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var selectedCountryName: String {
        if let countryCode = appState.selectedCountry,
           let country = countries.first(where: { $0.code == countryCode }) {
            return country.name
        }
        return "None"
    }
    
    @Query(sort: \HDHomeRunServer.deviceId, order: .forward) private var devices: [HDHomeRunServer]
    @Query(sort: \IPTVCountry.name, order: .forward) private var countries: [IPTVCountry]

    var body: some View {
        Form {
            Section("Country") {
                NavigationLink {
                    CountryPickerView(
                        countries: filteredCountries,
                        selectedCountry: $appState.selectedCountry
                    )
                } label: {
                    HStack {
                        Text("Select a country")
                        Spacer()
                        Text(selectedCountryName)
                    }
                }
            }
            
            Section("HD HomeRun Tuners") {
                Toggle("Scan for Tuners", isOn: $appState.scanForTuners)
                    .toggleStyle(FocusedToggleStyle())

                if appState.scanForTuners {
                    ForEach(devices) { device in
                        @Bindable var bindableDevice = device
                        Toggle("\(device.deviceId) \(device.friendlyName)",
                               isOn: $bindableDevice.includeChannelLineUp)
                        .toggleStyle(FocusedToggleStyle())
                        
                    }
                }
            }
        }
    }
}

// MARK: - Focusable Button

struct TVButtonStyle: ButtonStyle {
    
    @Environment(\.isFocused) var focused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                Capsule()
                    .fill(focused ?
                        .guideBackgroundFocused : .guideBackgroundNoFocus)
            )
            .foregroundColor(focused ?
                .guideForegroundFocused : .guideForegroundNoFocus)
            .scaleEffect(focused ? 1.01 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
            .animation(.easeOut(duration: 0.2), value: focused)
    }
}

// MARK: - FocusableToggle

struct FocusedToggleStyle: ToggleStyle {

    @Environment(\.isFocused) var isFocused: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                //                    .foregroundColor(isFocused ?
                //                        .guideForegroundFocused : .guideForegroundNoFocus)
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                Spacer()
                
                // Switch
                Rectangle()
                    .foregroundColor(configuration.isOn ? Color.mainAppTheme : .toggleOffBackground)
                    .frame(width: 55, height: 35, alignment: .center)
                    .overlay(
                        Circle()
                            .foregroundColor(.white)
                            .padding(.all, 3)
                            .overlay(
                                Image(systemName: configuration.isOn ? "checkmark" : "xmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12,
                                           height: 12,
                                           alignment: .center)
                                    .foregroundColor(.toggleOffBackground)
                            )
                            .offset(x: configuration.isOn ? 11 : -11, y: 0)
                            .animation(.easeOut(duration: 0.2),
                                       value: configuration.isOn)
                    )
                    .cornerRadius(17.5)
            }
        }
        .buttonStyle(.plain)
        .onChange(of: isFocused) { oldValue, newValue in
            if isFocused {
                logDebug("ToggleView Focused")
            } else {
                logDebug("ToggleView lost focus")
            }
        }
    }
}

// MARK: - Previews

#Preview("ToggleView") {
   
    Toggle("Toggle View", isOn: .constant(true))
        .toggleStyle(FocusedToggleStyle())
        
}
