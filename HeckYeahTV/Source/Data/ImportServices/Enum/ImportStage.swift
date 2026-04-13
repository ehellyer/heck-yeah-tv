//
//  ImportStage.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/13/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

enum ImportStage {
    case homeRunProbe
    case homeRunDeviceInterrogation
    case homeRunChannels
    case homeRunGuides
    
    case iptvBlocklists
    case iptvCategories
    case iptvChannels
    case iptvCountries
    case iptvFeeds
    case iptvGuides
    case iptvLanguages
    case iptvLogos
    case iptvRegions
    case iptvStreams
    case iptvSubdivisions
    case iptvTimezones
    
    var description: String {
        switch self {
            case .homeRunProbe: return "Probe Network"
            case .homeRunDeviceInterrogation: return "Device Interrogation"
            case .homeRunChannels: return "Channel Lineup"
            case .homeRunGuides: return "Channel Guide"
                
            case .iptvGuides: return "IPTV Guide"
            case .iptvChannels: return "IPTV Lineup"
            case .iptvBlocklists: return "Blocklists"
            case .iptvCategories: return "Categories"
            case .iptvCountries: return "Countries"
            case .iptvRegions: return "Regions"
            case .iptvFeeds: return "Feeds"
            case .iptvLogos: return "Logos"
            case .iptvStreams: return "Streams"
            case .iptvLanguages: return "Languages"
            case .iptvTimezones: return "Timezones"
            case .iptvSubdivisions: return "Subdivisions"
        }
    }
}
