//
//  HomeRunDataSources.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Provides the root URLs for HDHomeRun tuner discovery API and the TV Listing API.
///
/// When connected to the same network, for WebUI access to each device use `http://{deviceId}.local`
///
///    e.g.  [http://10A81C77.local](http://10A81C77.local)
///
/// The deviceId can be found on the underside of the device.  If the deviceId is not known, alternatively you can use [http://hdhomerun.local/](http://hdhomerun.local/)
/// However, if there is more than one device on the network, this method will only return the first discovered device.  You must then use the
/// deviceId URL to access each device directly.
///
struct HomeRunDataSources {
    struct Tuner {
        static let discoveryURL = URL(string: "https://api.hdhomerun.com/discover")!
    }
    struct TVListings {
        static let guideURL = URL(string: "https://api.hdhomerun.com/api/guide")!
    }
}
