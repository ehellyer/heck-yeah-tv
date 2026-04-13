//
//  HomeRunDevice+HDHomeRunDiscovery.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/13/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

extension HomeRunDevice {
    
    var homeRunDiscovery: HDHomeRunDiscovery? {
        
        guard let ip = self.baseURL.host() else { return nil }
        
        let discoveryType = HDHomeRunDiscovery(deviceId: self.deviceId,
                                               localIP: ip,
                                               baseURL: self.baseURL,
                                               discoverURL: self.baseURL.appendingPathComponent("discover.json"),
                                               lineupURL: self.lineupURL)
        
        return discoveryType
    }
}
