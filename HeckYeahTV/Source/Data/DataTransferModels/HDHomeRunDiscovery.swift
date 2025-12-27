//
//  HDHomeRunDiscovery.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

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

extension HDHomeRunDiscovery {
    
    enum CodingKeys: String, CodingKey {
        case deviceId = "DeviceID"
        case localIP = "LocalIP"
        case baseURL = "BaseURL"
        case discoverURL = "DiscoverURL"
        case lineupURL = "LineupURL"
    }
}
