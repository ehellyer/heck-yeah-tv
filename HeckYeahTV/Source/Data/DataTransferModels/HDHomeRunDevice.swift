//
//  HDHomeRunDevice.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// HDHomeRunDevice - After initial discover call to find HDHomeRun Devices on the network, a device discover call is made and returns details on the specific device.
/// 
/// e.g. [http://192.168.78.220/discover.json](http://192.168.78.220/discover.json) -> `HDHomeRunDevice`
struct HDHomeRunDevice: JSONSerializable, Equatable {
    
    let friendlyName: String
    let modelNumber: String
    let firmwareName: String
    let firmwareVersion: String
    let deviceId: HDHomeRunDeviceId
    let deviceAuth: String
    let baseURL: URL
    let lineupURL: URL
    let tunerCount: Int
}

//MARK: - JSONSerializable customization

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
