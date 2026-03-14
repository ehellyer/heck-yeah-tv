//
//  ChannelBundleFilterViewModel.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/14/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class ChannelBundleFilterViewModel {
    
    // MARK: - Properties
    
    var searchTerm: String = ""
    var selectedCountry: CountryCodeId
    var selectedCategory: CategoryId?
    
    // MARK: - Lifecycle
    
    init(defaultCountry: CountryCodeId? = nil) {
        // Set default country from locale or fallback to "US"
        if let defaultCountry {
            self.selectedCountry = defaultCountry
        } else {
            self.selectedCountry = Locale.current.region?.identifier ?? "US"
        }
        self.selectedCategory = nil
    }
    
    // MARK: - Methods
    
    func resetToDefaults() {
        searchTerm = ""
        selectedCategory = nil
        selectedCountry = Locale.current.region?.identifier ?? "US"
    }
    
    /// Returns the trimmed search term, or nil if empty
    var trimmedSearchTerm: String? {
        let trimmed = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
