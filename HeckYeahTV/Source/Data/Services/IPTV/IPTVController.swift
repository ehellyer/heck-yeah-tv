//
//  IPTVController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/11/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// Source API:  [https://github.com/iptv-org/api](https://github.com/iptv-org/api)
actor IPTVController {
    
    deinit {
        logDebug("Deallocated")
    }
    
    private let sessionInterface = SessionInterface.sharedInstance
        
    ///MARK: - Internal API - Fetch IPTV Sources
    
    var categories: [IPCategory] = []
    var channels: [IPChannel] = []
    var countries: [Country] = []
    var feeds: [IPFeed] = []
    var logos: [IPLogo] = []
    var streams: [IPStream] = []
//    var blocklists: [IPBlocklist] = []
//    var guides: [IPGuide] = []
//    var languages: [Language] = []
//    var regions: [Region] = []
//    var subdivisions: [Subdivision] = []
//    var timezones: [Timezone] = []
    
    func fetchList<T: JSONSerializable>(url: URL) async throws -> T {
        // keep-alive off for initial connection. Example: Underlying layer 3/2 changes while app is running, e.g. VPN was on, then turned off or vice versa.
        let request = NetworkRequest(url: url,
                                     method: .get,
                                     timeoutInterval: 10.0,
                                     headers: [HTTPHeader.defaultUserAgent,
                                               HTTPHeader(name: "Accept-Encoding", value: "application/json"),
                                               HTTPHeader(name: "connection", value: "close")]) // keep-alive off for initial connection.  e.g. Avoid situations where VPN was on, then turned off while app was running, a new connection is needed.
        
        let response = try await self.sessionInterface.execute(request)
        let jsonObject = try T.initialize(jsonData: response.body)
        return jsonObject
    }
    
    func fetchAll() async -> FetchSummary {
        logDebug("Discovering IPTV channels... 🇺🇸")
        var source = IPTVDataSources()
        source.summary.startedAt = Date()
        
        let specs: [AnyLoadSpec] = [
            LoadSpec(.streams) { controller, items in controller.streams = items },
            LoadSpec(.channels) { controller, items in controller.channels = items },
            LoadSpec(.countries) { controller, items in controller.countries = items },
            LoadSpec(.categories) { controller, items in controller.categories = items },
            LoadSpec(.feeds) { controller, items in controller.feeds = items },
            LoadSpec(.logos) { controller, items in controller.logos = items }
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
        logDebug("IPTV channel discovery completed. 🏁")
        return source.summary
    }
}

protocol AnyLoadSpec {
    var endpoint: IPTVDataSources.Endpoint { get }
    func load(into controller: isolated IPTVController) async throws -> Int
}

struct LoadSpec<T: JSONSerializable>: AnyLoadSpec {
    
    init(_ endpoint: IPTVDataSources.Endpoint, 
         setter: @escaping (isolated IPTVController, [T]) -> Void) {
        self.endpoint = endpoint
        self.url = endpoint.url
        self.setter = setter
    }
    
    private let url: URL
    private let setter: (isolated IPTVController, [T]) -> Void
    
    let endpoint: IPTVDataSources.Endpoint
    
    /// Fetches, assigns to the controller property, and returns the number of items loaded.
    func load(into controller: isolated IPTVController) async throws -> Int {
        let items: [T] = try await controller.fetchList(url: url)
        setter(controller, items)
        return items.count
    }
}
