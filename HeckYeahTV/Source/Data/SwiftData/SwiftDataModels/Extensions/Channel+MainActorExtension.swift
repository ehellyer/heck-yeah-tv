//
//  Channel+Extension.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/23/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

@MainActor
extension Channel {
    
    var displayChannelNumber: String? {
        if deviceId != IPTVImporter.iptvDeviceId, let _number = number {
            return _number
        } else {
            return nil
        }
    }
    
    var qualityImage: Image? {
        guard let image = quality.image else {
            return nil
        }
        return image.asImage
    }
    
    var languageText: String? {
        return languages.first?.uppercased()
    }
    
    var noSubText: Bool {
        return number == nil
        && quality == .unknown
        && hasDRM == false
        && languageText == nil
    }
    
    /// Returns the appropriate flag for the channel's country. Falls back to your device's locale when the channel claims to be from "anywhere," because some channels have commitment issues.
    /// Note: Channels with country of "any" are channels from the users LAN based tuners.
    var countryFlag: Image? {
        let localeCountryCode = Locale.current.region?.identifier.lowercased() ?? "us"
        
        var countryCode = country?.lowercased()
        if countryCode == "uk" { countryCode = "gb" } //Temp fix.
        countryCode = (countryCode == "any" ? localeCountryCode : countryCode)
        guard let countryCode else {
            return nil
        }
        
        let image = PlatformImage(named: countryCode)?.asImage
        return image
    }
}
