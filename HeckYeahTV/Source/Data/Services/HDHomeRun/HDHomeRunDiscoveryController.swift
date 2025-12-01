//
//  HDHomeRunDiscoveryController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// HDHomeRunDiscoveryController
///
/// e.g. [https://api.hdhomerun.com/discover](https://api.hdhomerun.com/discover)
@MainActor
final class HDHomeRunDiscoveryController {
    
    //MARK: - Private API
    
    private let sessionInterface = SessionInterface.sharedInstance
    // keep-alive off for initial connection. Example: Underlying layer 3/2 changes while app is running, e.g. VPN was on, then turned off or vice versa.
    private var defaultHeaders: [HTTPHeader] = [HTTPHeader.defaultUserAgent,
                                                HTTPHeader(name: "Accept-Encoding", value: "application/json"),
                                                HTTPHeader(name: "connection", value: "close")
    ]
    
    private func deviceDiscovery() async -> FetchSummary {
        var summary = FetchSummary()
        let hdHomeRunDiscoveryURL = HDHomeRunKeys.Tuner.hdHomeRunDiscoveryURL
        let request = NetworkRequest(url: hdHomeRunDiscoveryURL,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: self.defaultHeaders)
        do {
            // Test the DataResponse async
            let response = try await self.sessionInterface.execute(request)
            self.discoveredDevices = try [HDHomeRunDiscovery].initialize(jsonData: response.body)
            summary.successes[hdHomeRunDiscoveryURL] = discoveredDevices.count
        } catch {
            summary.failures[hdHomeRunDiscoveryURL] = error
        }
       
        summary.finishedAt = Date()
        return summary
    }

    private func deviceDetails() async -> FetchSummary {
        var summary = FetchSummary()

        var tunerDevices: [HDHomeRunDevice] = []
        for device in discoveredDevices {
            let deviceURL = device.discoverURL
            let request = NetworkRequest(url: deviceURL,
                                         method: .get,
                                         timeoutInterval: 10.0,
                                         headers: self.defaultHeaders)
            do {
                // Test the JSONSerializableResponse async
                let response: JSONSerializableResponse<HDHomeRunDevice> = try await self.sessionInterface.execute(request)
                let tuner = response.jsonObject
                tunerDevices.append(tuner)
                summary.successes[deviceURL] = 1
            } catch {
                summary.failures[deviceURL] = error
            }
        }
        self.devices = tunerDevices
        
        summary.finishedAt = Date()
        return summary
    }
    
    private func channelLineUp(_ tunerServerDevice: HDHomeRunDevice) async -> FetchSummary {
        var summary = FetchSummary()
        let request = NetworkRequest(url: tunerServerDevice.lineupURL,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: self.defaultHeaders)
        do {
            let response = try await self.sessionInterface.execute(request)

            // Pass along the deviceId in codingUserInfo so that the deviceId can be passed along into the decoding init of the `HDHomeRunChannel` model.
            let codingUserInfo: [CodingUserInfoKey : any Sendable] = [CodingUserInfoKey.homeRunDeviceIdKey: tunerServerDevice.deviceId]
            self.channels = try [HDHomeRunChannel].initialize(jsonData: response.body, codingUserInfo: codingUserInfo)
            summary.successes[tunerServerDevice.lineupURL] = channels.count
        } catch {
            summary.failures[tunerServerDevice.lineupURL] = error
        }
        
        summary.finishedAt = Date()
        return summary
    }
    
    //MARK: - Internal API
    
    var discoveredDevices: [HDHomeRunDiscovery] = []
    var devices: [HDHomeRunDevice] = []
    var channels: [HDHomeRunChannel] = []
    
    func bootStrapTunerChannelDiscovery() async -> FetchSummary {
        logDebug("Looking for HDHomeRun Tuners and discovering their channels. 🏳️")
        let summary = await deviceDiscovery()
        if discoveredDevices.count > 0 {
            summary.mergeSummary(await deviceDetails())
        }
        
        for device in devices {
            let _summary = await channelLineUp(device)
            summary.mergeSummary(_summary)
        }
        logDebug("HDHomeRun discovery completed. 🏁")
        return summary
    }
}
