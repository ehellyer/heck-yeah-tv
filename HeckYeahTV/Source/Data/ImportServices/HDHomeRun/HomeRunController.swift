//
//  HomeRunController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// The maestro of HDHomeRun device discovery and channel wrangling.
///
/// This actor handles all the heavy lifting of finding HDHomeRun tuners on your network,
/// interrogating them for their channel lineups, and fetching guide data. Think of it as
/// a friendly neighborhood network archaeologist, digging up all those sweet OTA channels.
///
/// Being an actor means it plays nice with Swift concurrency and won't step on its own toes
/// when multiple requests come flying in. It's polite like that.
actor HomeRunController {
    
    deinit {
        logDebug("Deallocated")
    }
    
    //MARK: - Private API
    
    /// Our trusty network session manager. Shared because we're team players.
    private let sessionInterface: SessionInterface = SessionInterface.sharedInstance
    
    /// HTTP headers with keep-alive explicitly disabled.
    ///
    /// Why the hostility toward keep-alive? Because network conditions change faster than a channel surfer
    /// during commercial breaks. VPNs toggle on/off, WiFi switches to cellular, your neighbor's microwave
    /// kicks in... We need fresh connections each time to deal with these layer 2/3 shenanigans.
    private var defaultHeaders: [HTTPHeader] = [HTTPHeader.defaultUserAgent,
                                                HTTPHeader(name: "Accept-Encoding", value: "application/json"),
                                                HTTPHeader(name: "connection", value: "close")]
    
    /// Matches up channel logos from guide data with their respective channels.
    ///
    /// This function plays matchmaker between channels and their logos by indexing guide data
    /// for fast lookups. It's like a dating app for channels and their visual identities.
    ///
    /// - Parameters:
    ///   - channelGuides: Array of channel guide data containing logo URLs
    ///   - channels: Array of channels to update (modified in place)
    private func updateChannelLogos(channelGuides: [HDHomeRunChannelGuide], channels: inout [HDHomeRunChannel]) {
        guard channelGuides.isEmpty == false, channels.isEmpty == false else {
            logWarning("No channel guide or channel data available to update channel logo.")
            return
        }
        
        let indexedLogos: [GuideNumber: URL] = channelGuides.reduce(into: [:]) { result, guide in
            result[guide.guideNumber] = guide.logoURL
        }
        
        for i in channels.indices {
            channels[i].logoURL = indexedLogos[channels[i].guideNumber]
        }
    }
    
    //MARK: - Internal API

    /// Scans the network for HDHomeRun tuner devices like a digital metal detector.
    ///
    /// This function sends out discovery broadcasts to find HDHomeRun tuners lurking on your network.
    /// You can either let it scan the whole network or aim directly at a specific IP if you know where
    /// your tuner is hiding.
    ///
    /// - Parameter targetIP: Optional IP address to probe directly. If nil, scans the entire network.
    /// - Returns: Array of discovered HDHomeRun devices with their URLs all nicely packaged
    /// - Throws: If the network probe fails or no tuners are found
    func probeNetwork(targetIP: String? = nil) async throws -> [HDHomeRunDiscovery] {
        let deviceType = HDHomeRunProbe.HDHomeRunDeviceType_Tuner
        let probe = HDHomeRunProbe()
        let devices = try await probe.discoverDevices(targetIP: targetIP)
        
        let homeRunDiscovery: [HDHomeRunDiscovery] = Set(devices.filter({ $0.deviceType == deviceType })).compactMap({
            guard let baseURL = URL(string: $0.baseURL),
                  let discoverURL = URL(string: "http://\($0.ipAddress)/discover.json"),
                  let lineupURL = URL(string: "http://\($0.ipAddress)/lineup.json") else { return nil }
            
            return HDHomeRunDiscovery(deviceId: $0.deviceID,
                                      localIP: $0.ipAddress,
                                      baseURL: baseURL,
                                      discoverURL: discoverURL,
                                      lineupURL: lineupURL)
        })
        
        return homeRunDiscovery
    }
    
    /// Interrogates a discovered device for its vital statistics.
    ///
    /// Once we've found a device, this function asks it nicely for its complete details including
    /// model number, firmware version, and all the good stuff. Like a polite job interview.
    ///
    /// - Parameter discoveredDevice: The device to interrogate
    /// - Returns: Fully populated device information
    /// - Throws: If the device is uncooperative or network issues occur
    func deviceDetails(_ discoveredDevice: HDHomeRunDiscovery) async throws -> HDHomeRunDevice {
        let deviceURL = discoveredDevice.discoverURL
        let request = NetworkRequest(url: deviceURL,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: self.defaultHeaders)
        
        let response: JSONSerializableResponse<HDHomeRunDevice> = try await self.sessionInterface.execute(request)
        let tuner = response.jsonObject
        
        return tuner
    }
    
    /// Fetches the complete channel lineup from a tuner device.
    ///
    /// This is where we get the good stuff: all the channels this tuner knows about. Each channel
    /// gets tagged with the device ID so we know which tuner to use when it's showtime.
    ///
    /// Uses a custom JSON decoder context to smuggle the device ID into each channel during decoding.
    /// It's not sneaky, it's just efficient data plumbing.
    ///
    /// - Parameter tunerDevice: The tuner to query for channels
    /// - Returns: Array of channels with all their streaming URLs ready to go
    /// - Throws: If the lineup fetch fails or JSON decoding goes sideways
    func channelLineUp(_ tunerDevice: HDHomeRunDevice) async throws -> [HDHomeRunChannel] {
        let request = NetworkRequest(url: tunerDevice.lineupURL,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: self.defaultHeaders)
        
        // Here we prefer to use a `DataResponse` so we can call the JSON initializer and pass deviceId into the JSON decoder context.
        let response: DataResponse = try await self.sessionInterface.execute(request)
        
        // Set the deviceId in codingUserInfo so that it can be passed along into the JSON decoder initializer of the `HDHomeRunChannel` model.  (See init override in HDHomeRunChannel)
        let codingUserInfo: [CodingUserInfoKey : any Sendable] = [CodingUserInfoKey.homeRunDeviceIdKey: tunerDevice.deviceId]
        let channels = try [HDHomeRunChannel].initialize(jsonData: response.body, codingUserInfo: codingUserInfo)
        
        return channels
    }
    
    /// Fetches electronic program guide (EPG) data from HDHomeRun's cloud service.
    ///
    /// Want to know what's on TV? This function hits up HDHomeRun's servers to get the TV listings.
    /// You can specify a time range and even filter by specific channels if you're feeling picky.
    ///
    /// - Parameters:
    ///   - deviceAuth: Device authentication token (like a VIP backstage pass)
    ///   - start: Optional Unix timestamp for when to start the guide data
    ///   - duration: Optional hours of guide data to fetch (default is 24 if you're living in the now)
    ///   - channelNumber: Optional specific channel to fetch guide for. Nil means "give me everything"
    /// - Returns: Array of channel guides with program information and logo URLs
    /// - Throws: If the URL is malformed or the network request fails
    func channelGuideFetch(deviceAuth: String,
                           start: Int?,
                           duration: Int?,
                           channelNumber: String?) async throws -> [HDHomeRunChannelGuide] {
        
        let guideURL = HomeRunDataSources.TVListings.guideURL
        
        // Build query string using map to unwrap optional types.
        var homeRunDiscoveryURL: URLComponents? = URLComponents(string: guideURL.absoluteString)
        homeRunDiscoveryURL?.queryItems = [URLQueryItem(name: "DeviceAuth", value: deviceAuth)]
        start.map { homeRunDiscoveryURL?.queryItems?.append(URLQueryItem(name: "Start", value: "\($0)")) }
        duration.map { homeRunDiscoveryURL?.queryItems?.append(URLQueryItem(name: "Duration", value: "\($0)")) }
        channelNumber.map { homeRunDiscoveryURL?.queryItems?.append(URLQueryItem(name: "Channel", value: $0)) }
        
        guard let url = homeRunDiscoveryURL?.url else {
            throw HomeRunControllerError.invalidURL
        }
        
        let request = NetworkRequest(url: url,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: self.defaultHeaders)
        
        let response: JSONSerializableResponse<[HDHomeRunChannelGuide]> = try await self.sessionInterface.execute(request)
        let channelGuides: [HDHomeRunChannelGuide] = response.jsonObject
        
        return channelGuides
    }
    
    /// The grand unified theory of HDHomeRun data acquisition.
    ///
    /// This is the all-in-one, set-it-and-forget-it function that does the whole shebang:
    /// 1. Scans for devices (or targets a specific one)
    /// 2. Gets detailed info from each device
    /// 3. Fetches channel lineups
    /// 4. Optionally grabs guide data and matches up logos
    ///
    /// It's like ordering the combo meal instead of à la carte. Everything gets logged and
    /// summarized so you know exactly what succeeded, what failed, and why your tuner is being difficult.
    ///
    /// - Parameters:
    ///   - targetDevice: Optional specific device to target. If nil, discovers all devices on the network
    ///   - includeGuideData: Whether to fetch program guide data (adds time but gives you the TV listings)
    /// - Returns: Complete discovery result with all devices, channels, guides, and a detailed summary
    func fetchAll(targetDevice: HDHomeRunDiscovery? = nil, includeGuideData: Bool) async -> HomeRunDiscoveryResult {
        logDebug("Looking for HDHomeRun Tuners, obtaining channel line up and fetching guide information. 🇺🇸")
        
        var summary = FetchSummary()

        var discoveredDevices: [HDHomeRunDiscovery] = []
        do {
            discoveredDevices = try await self.probeNetwork(targetIP: targetDevice?.localIP)
            let message = "Network probe completed.  \(targetDevice != nil ? "Targeted device ip: \(targetDevice!.localIP)" : "\(discoveredDevices.count) devices found.")"
            summary.addSuccess(forKey: .homeRunProbe, value: message)
            logDebug(message)
        } catch {
            let message = "Error probing \(targetDevice != nil ? "targeted device ip: \(targetDevice!.localIP)" : "network for HomeRun devices").  Error: \(error.localizedDescription)"
            summary.addFailure(forKey: .homeRunProbe, value: message)
            logError(message)
        }

        var devices: [HDHomeRunDevice] = []
        do {
            for discoveredDevice in discoveredDevices {
                let device = try await self.deviceDetails(discoveredDevice)
                devices.append(device)
                let message = "Device details obtained for \(device.deviceId)"
                summary.addSuccess(forKey: .homeRunDeviceInterrogation, value: message)
                logDebug(message)
            }
        } catch {
            let message = "Error obtaining device details.  Error: \(error.localizedDescription)"
            summary.addFailure(forKey: .homeRunDeviceInterrogation, value: message)
            logError(message)
        }
        
        var channels: [HDHomeRunChannel] = []
        for device in devices {
            do {
                let deviceChannels = try await channelLineUp(device)
                channels.append(contentsOf: deviceChannels)
                let message = "Channels retrieved for deviceId: \(device.deviceId).  Found \(deviceChannels.count) channels"
                summary.addSuccess(forKey: .homeRunChannels, value: message)
                logDebug(message)
            } catch {
                let message = "Error obtaining deviceId: \(device.deviceId) details.  Error: \(error.localizedDescription)"
                summary.addFailure(forKey: .homeRunChannels, value: message)
                logError(message)
            }
        }

        var channelGuides: [HDHomeRunChannelGuide] = []
        if includeGuideData && not(devices.isEmpty) && not(channels.isEmpty) {
            for device in devices {
                do {
                    channelGuides = try await channelGuideFetch(deviceAuth: device.deviceAuth, start: nil, duration: 24, channelNumber: nil)
                    let message = "Found \(channelGuides.count) HDHomeRun channels with programs."
                    summary.addSuccess(forKey: .homeRunGuides, value: message)
                    logDebug(message)
                } catch {
                    let message = "Error obtaining channel guide.  Error: \(error.localizedDescription)"
                    summary.addFailure(forKey: .homeRunGuides, value: message)
                    logError(message)
                }
            }
            updateChannelLogos(channelGuides: channelGuides, channels: &channels)
        }
        
        let homeRunDiscovery = HomeRunDiscoveryResult(fetchGuideDataRequested: includeGuideData,
                                                      targetedDevice: targetDevice,
                                                      discoveredDevices: discoveredDevices,
                                                      devices: devices,
                                                      channels: channels,
                                                      channelGuides: channelGuides,
                                                      summary: summary)
        
        logDebug("HDHomeRun discovery completed. 🏁")
        return homeRunDiscovery
    }
}
