//
//  HomeRunDiscoveryController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftUI
import Hellfire

enum HomeRunChannelGuideError: LocalizedError {
    case invalidURL
    
    var errorDescription: String? {
        switch self {
            case .invalidURL:
                return "The URL could not be formed due to malformed data."
        }
    }
}


actor HomeRunDiscoveryController {
    
    deinit {
        logDebug("Deallocated")
    }
    
    //MARK: - Private API
    
    private let sessionInterface: SessionInterface = SessionInterface.sharedInstance
    
    // keep-alive off for this request. Example: Underlying layer 3/2 changes while app is running, e.g. VPN was on, then turned off or vice versa.
    private var defaultHeaders: [HTTPHeader] = [HTTPHeader.defaultUserAgent,
                                                HTTPHeader(name: "Accept-Encoding", value: "application/json"),
                                                HTTPHeader(name: "connection", value: "close")]
    
    private func deviceDiscovery() async -> FetchSummary {
        var summary = FetchSummary()
        let discoveryURL = HomeRunDataSources.Tuner.discoveryURL
        let request = NetworkRequest(url: discoveryURL,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: self.defaultHeaders)
        do {
            let response = try await self.sessionInterface.execute(request)
            self.discoveredDevices = try [HDHomeRunDiscovery].initialize(jsonData: response.body)
            summary.successes[discoveryURL] = discoveredDevices.count
        } catch {
            summary.failures[discoveryURL] = error
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
    
    /// Fetches program guide data for HDHomeRun channels from the guide service.
    ///
    /// This method constructs a request to the HDHomeRun guide service API, combining device authentication
    /// from all discovered tuners to retrieve program listings. The guide data includes program titles,
    /// descriptions, air times, and other metadata for the specified time range.
    ///
    /// - Parameters:
    ///   - devices: A list of active HDHomeRun devices discovered on the network. Used to concatenate the
    ///              DeviceAuth strings from all HDHomeRun devices for authentication with the guide service.
    ///   - start: Optional. Unix timestamp of the start of the time range requested. Default = current time.
    ///   - duration: Optional. Number of hours of the time range requested. Default = 4, Max = 24.
    ///   - channelNumber: Optional. Specific channel number to request guide data for. Default = all channels.
    ///
    /// - Returns: A `FetchSummary` containing success/failure information for the guide data fetch operation,
    ///            including the number of channel guides retrieved and any errors encountered.
    private func channelGuideFetch(devices: [HDHomeRunDevice],
                                    start: Int?,
                                    duration: Int?,
                                    channelNumber: String?) async -> FetchSummary {
        
        var summary = FetchSummary()
        var homeRunDiscoveryURL = URLComponents(string: HomeRunDataSources.TVListings.guideURL.absoluteString)

        let deviceAuth = devices.reduce("") { accumulator, device in
            accumulator + device.deviceAuth
        }

        //Build query string, (using map to unwrap optional types)
        homeRunDiscoveryURL?.queryItems = [URLQueryItem(name: "DeviceAuth", value: deviceAuth)]
        start.map {
            homeRunDiscoveryURL?.queryItems?.append(URLQueryItem(name: "Start", value: "\($0)"))
        }
        duration.map {
            homeRunDiscoveryURL?.queryItems?.append(URLQueryItem(name: "Duration", value: "\($0)"))
        }
        channelNumber.map {
            homeRunDiscoveryURL?.queryItems?.append(URLQueryItem(name: "Channel", value: $0))
        }
        
        guard let url = homeRunDiscoveryURL?.url else {
            summary.failures[HomeRunDataSources.TVListings.guideURL] = HomeRunChannelGuideError.invalidURL
            return summary
        }
        
        let request = NetworkRequest(url: url,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: self.defaultHeaders)
        
        do {
            let response = try await self.sessionInterface.execute(request)
            channelGuides = try [HDHomeRunChannelGuide].initialize(jsonData: response.body)
            
            let _indexedLogos: [String: URL] = channelGuides.reduce(into: [:]) { result, guide in
                result[guide.guideNumber] = guide.logoURL
            }
            indexedLogos = _indexedLogos
            
            summary.successes[url] = channelGuides.count
        } catch {
            summary.failures[url] = error
        }
        
        return summary
    }
    
    //MARK: - Internal API
    
    var discoveredDevices: [HDHomeRunDiscovery] = []
    var devices: [HDHomeRunDevice] = []
    var channels: [HDHomeRunChannel] = []
    var channelGuides: [HDHomeRunChannelGuide] = []
    var indexedLogos: [GuideNumber: URL] = [:] //Indexed on HDHomeRunChannel.guideNumber.
    
    func fetchAll(includeGuideData: Bool) async -> FetchSummary {
        logDebug("Looking for HDHomeRun Tuners, obtaining channel line up and fetching guide information. 🇺🇸")
        
        var summary = await deviceDiscovery()
        if discoveredDevices.count > 0 {
            summary.mergeSummary(await deviceDetails())
        }
        
        for device in devices {
            let _summary = await channelLineUp(device)
            summary.mergeSummary(_summary)
        }
        
        if includeGuideData && channels.count > 0 {
            let _summary = await channelGuideFetch(devices: devices, start: nil, duration: 24, channelNumber: nil)
            summary.mergeSummary(_summary)
            
            if channelGuides.count > 0 {
                logDebug("Found \(channelGuides.count) HDHomeRun channels with programs.")
                for i in channels.indices {
                    channels[i].logoURL = indexedLogos[channels[i].guideNumber]
                }
            } else {
                logWarning("No HDHomeRun channel program data was returned from the guide API.")
            }
        }
        
        logDebug("HDHomeRun discovery completed. 🏁")
        return summary
    }
}
