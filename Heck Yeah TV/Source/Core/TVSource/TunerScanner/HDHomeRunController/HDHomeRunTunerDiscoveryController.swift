//
//  HDHomeRunTunerDiscoveryController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// HDHomeRunTunerDiscoveryController
///
/// e.g. [https://api.hdhomerun.com/discover](https://api.hdhomerun.com/discover)
@MainActor
final class HDHomeRunTunerDiscoveryController {
    
    //MARK: - Private API
    
    private var sessionInterface = SessionInterface.sharedInstance
    private var defaultHeaders: [HTTPHeader] = [HTTPHeader.defaultUserAgent,
                                                HTTPHeader(name: "Accept-Encoding", value: "application/json"),
                                                HTTPHeader(name: "connection", value: "close") // keep-alive off
    ]

    private func tunerServerDetails(_ discoveredTuners: [HDHomeRunDevice]) async throws -> [HDHomeRunTuner] {
        var tunerDevices: [HDHomeRunTuner] = []
        for discoveredTuner in discoveredTuners {
            let discoverURL = discoveredTuner.discoverURL
            let request = NetworkRequest(url: discoverURL,
                                         method: .get,
                                         headers: self.defaultHeaders)
            let response = try await self.sessionInterface.execute(request)
            let tuner = try HDHomeRunTuner.initialize(jsonData: response.body)
            tunerDevices.append(tuner)
        }
        return tunerDevices
    }

    private func discoverTuners() async throws {
        let hdHomeRunDiscoveryURL = HDHomeRunKeys.Tuner.hdHomeRunDiscoveryURL
        let request = NetworkRequest(url: hdHomeRunDiscoveryURL,
                                     method: .get,
                                     headers: self.defaultHeaders)
        let response = try await self.sessionInterface.execute(request)
        let discoveredDevices: [HDHomeRunDevice] = try [HDHomeRunDevice].initialize(jsonData: response.body)
        discoveredTuners = try await self.tunerServerDetails(discoveredDevices)
        if let tuner = discoveredTuners.first {
            try await self.tunerChannelLineUp(tuner)
        }
    }
    
    private func tunerChannelLineUp(_ tunerServerDevice: HDHomeRunTuner) async throws {
        let request = NetworkRequest(url: tunerServerDevice.lineupURL,
                                     method: .get,
                                     headers: self.defaultHeaders)
        let response = try await self.sessionInterface.execute(request)
        channels = try [Channel].initialize(jsonData: response.body)
    }

    
    //MARK: - Internal API
    
    var discoveredTuners: [HDHomeRunTuner] = []
    var channels: [Channel] = []
    
    func bootStrapTunerChannelDiscovery() async throws {
        try await discoverTuners()
    }
}
