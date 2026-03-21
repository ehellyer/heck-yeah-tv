//
//  HDHomeRunDiscovery.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// HDHomeRunDeviceId is the unique identifier of a `HomeRuneDevice` (tuner server SwiftData model) and `HDHomeRunDiscovery` / `HDHomeRunDevice` DTO's.
///
/// IMPORTANT: In early stages of development a `Channel` had both a source type and a device Id properties.  The source type determined where the channel came from, either sourced from
/// internet (IPTV), or sourced from a `HomeRunDevice`.
/// The deviceId therefore had to be optional and only had a value when the channel was from a `HomeRunDevice`.  Later it was determined that if we just put "IPTV" in the deviceId property, then
/// deviceId can serve both purposes of describing source type and identifying the `HomeRunDevice` and no longer had to be optional.  The source type property was removed from `Channel`.
typealias HDHomeRunDeviceId = String

/// HDHomeRunDiscovery - Local network scan for HDHomeRun tuner servers (e.g The little black box with one or more tuners inside).  Returned as an array of `HDHomeRunDiscovery`.
///
/// e.g. [https://api.hdhomerun.com/discover](https://api.hdhomerun.com/discover) -> `[HDHomeRunDiscovery]`
struct HDHomeRunDiscovery: JSONSerializable, Equatable  {
    
    let deviceId: HDHomeRunDeviceId
    let localIP: String
    let baseURL: URL
    let discoverURL: URL
    let lineupURL: URL
}

//MARK: - JSONSerializable customization

extension HDHomeRunDiscovery {
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "DeviceID"
        case localIP = "LocalIP"
        case baseURL = "BaseURL"
        case discoverURL = "DiscoverURL"
        case lineupURL = "LineupURL"
    }
}
