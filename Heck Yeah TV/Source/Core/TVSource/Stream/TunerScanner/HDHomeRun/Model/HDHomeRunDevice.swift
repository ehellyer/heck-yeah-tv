//
//  HDHomeRunDevice.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire


/// Returns an array of HDHomeRun Devices found on the local network.  Each device will provide it's own details and channel line up URL.
struct HDHomeRunKeys {
    struct Tuner {
        static var hdHomeRunDiscoveryURL = URL(string: "https://api.hdhomerun.com/discover")!
    }
}

/// HDHomeRunDevice - After initial discover call to find HDHomeRun Devices on the network, a device discover call is made and returns details on the specific device.
/// 
/// e.g. [http://192.168.50.250/discover.json](http://192.168.50.250/discover.json) -> HDHomeRunDevice
struct HDHomeRunDevice: JSONSerializable, Equatable {
    
    let friendlyName: String
    let modelNumber: String
    let firmwareName: String
    let firmwareVersion: String
    let deviceId: String
    let deviceAuth: String
    let baseURL: URL
    let lineupURL: URL
    let tunerCount: Int
}

extension HDHomeRunDevice {
    
    enum CodingKeys: String, CodingKey {
        case friendlyName = "FriendlyName"
        case modelNumber = "ModelNumber"
        case firmwareName = "FirmwareName"
        case firmwareVersion = "FirmwareVersion"
        case deviceId = "DeviceID"
        case deviceAuth = "DeviceAuth"
        case baseURL = "BaseURL"
        case lineupURL = "LineupURL"
        case tunerCount = "TunerCount"
    }
}
