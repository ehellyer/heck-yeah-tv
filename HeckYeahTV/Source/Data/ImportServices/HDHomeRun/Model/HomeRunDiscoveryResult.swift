//
//  HomeRunDiscoveryResult.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/13/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Represents the result of the fetchAll call on the HomeRunController.
struct HomeRunDiscoveryResult {
    
    /// Indicates if the guide data fetch was requested.  This is used to interpret the channelGuides empty state.
    var fetchGuideDataRequested: Bool
    
    /// The device that was targeted for a refresh.  When not nil, this is used to modify the behavior of the update to the store.  A general network probe will result in all available tuners being discovered and as such, any tuners currently in the store but not returned by the probe are considered to be offline.  But when we are targeting discovery we can only make an assumption about that one device being offline.  Any other devices already in the store will not have their status updated.
    var targetedDevice: HDHomeRunDiscovery?
    
    /// The devices that were discovered.
    var discoveredDevices: [HDHomeRunDiscovery]
    
    /// The device details as a result of interrogating the discovered devices.
    var devices: [HDHomeRunDevice]
    
    /// The channels of the discovered devices.
    var channels: [HDHomeRunChannel]
    
    /// The program guides of the channel lineup.
    var channelGuides: [HDHomeRunChannelGuide]
    
    /// A summary object 
    var summary: FetchSummary
}
