//
//  IPTVController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

@MainActor
final class IPTVController {
    
    private var sessionInterface = SessionInterface.sharedInstance
        
    ///MARK: - Internal API - Fetch IPTV Sources
    
    var blocklists: [IPBlocklist] = []
    var categories: [IPCategory] = []
    var channels: [IPChannel] = []
    var countries: [Country] = []
    var feeds: [IPFeed] = []
    var guides: [IPGuide] = []
    var languages: [Language] = []
    var logos: [IPLogo] = []
    var regions: [Region] = []
    var streams: [IPStream] = []
    var subdivisions: [Subdivision] = []
    var timezones: [Timezone] = []

    /// Result of network and country filters and a join between Channels and Streams.
    var filteredChannels: [IPChannel] = []
    
    func fetchList<T: JSONSerializable>(url: URL) async throws -> T {
        // keep-alive off for initial connection. Example: Underlying layer 3/2 changes while app is running, e.g. VPN was on, then turned off or vice versa.
        let request = NetworkRequest(url: url,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: [HTTPHeader.defaultUserAgent,
                                               HTTPHeader(name: "Accept-Encoding", value: "application/json"),
                                               HTTPHeader(name: "connection", value: "close")]) // keep-alive off for initial connection.  e.g. VPN was on, then turned off while app was running.
        
        let response = try await self.sessionInterface.execute(request)
        let jsonObject = try T.initialize(jsonData: response.body)
        return jsonObject
    }
    
    func fetchAll() async -> FetchSummary {
        var source = StreamSource()
        source.summary.startedAt = Date()
        
        let specs: [AnyLoadSpec] = [
            LoadSpec(.streams, keyPath: \.streams),
            LoadSpec(.channels, keyPath: \.channels)
        ]
        
        // Run everything concurrently; each task returns (endpoint, Result<count, error>)
        await withTaskGroup(of: (URL, Result<Int, Error>).self) { group in
            for spec in specs {
                group.addTask { [weak self] in
                    guard let self else {
                        return (spec.endpoint.url, .failure(CancellationError()))
                    }
                    
                    do {
                        let count = try await spec.load(into: self)
                        return (spec.endpoint.url, .success(count))
                    } catch {
                        return (spec.endpoint.url, .failure(error))
                    }
                }
            }
            
            // Aggregate results on the main actor (this method is @MainActor)
            for await (endpoint, result) in group {
                switch result {
                    case .success(let count):
                        source.summary.successes[endpoint] = count
                    case .failure(let error):
                        source.summary.failures[endpoint] = error
                }
            }
        }
        
        
        
        source.summary.finishedAt = Date()
        return source.summary
    }
}

protocol AnyLoadSpec {
    var endpoint: StreamSource.Endpoint { get }
    func load(into controller: IPTVController) async throws -> Int
}

struct LoadSpec<T: JSONSerializable>: AnyLoadSpec {
    
    init(_ endpoint: StreamSource.Endpoint, keyPath: ReferenceWritableKeyPath<IPTVController, [T]>) {
        self.endpoint = endpoint
        self.url = endpoint.url
        self.keyPath = keyPath
    }
    
    private let url: URL
    private let keyPath: ReferenceWritableKeyPath<IPTVController, [T]>
    
    let endpoint: StreamSource.Endpoint
    
    /// Fetches, assigns to the controller property, and returns the number of items loaded.
    func load(into controller: IPTVController) async throws -> Int {
        let items: [T] = try await controller.fetchList(url: url)
        controller[keyPath: keyPath] = items
        return items.count
    }
}
