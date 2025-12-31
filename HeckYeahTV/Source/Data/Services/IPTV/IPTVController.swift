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
    
    //MARK: - Private API
    
    private let sessionInterface = SessionInterface.sharedInstance
        
    private func fetchList<T: JSONSerializable>(url: URL) async throws -> T {
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

    protocol AnyLoadSpec {
        var endpoint: IPTVDataSources.Endpoint { get }
        func load(into controller: isolated IPTVController) async throws -> Int
    }
    
    private struct LoadSpec<T: JSONSerializable>: AnyLoadSpec {
        
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
    
    ///MARK: - Internal API - Fetch IPTV Sources
    
    private(set) var categories: [IPCategory] = []
    private(set) var channels: [IPChannel] = []
    private(set) var countries: [IPCountry] = []
    private(set) var feeds: [IPFeed] = []
    private(set) var indexedLogos: [ChannelId: URL] = [:]
    private(set) var indexedStreams: [String: IPStream] = [:]
//    var blocklists: [IPBlocklist] = []
//    var guides: [IPGuide] = []
//    var languages: [IPLanguage] = []
//    var regions: [IPRegion] = []
//    var subdivisions: [IPSubdivision] = []
//    var timezones: [IPTimezone] = []
    
    
    func fetchAll() async -> FetchSummary {
        logDebug("Discovering IPTV channels... 🇺🇸")
        var source = IPTVDataSources()
        source.summary.startedAt = Date()
        
        let specs: [AnyLoadSpec] = [
            LoadSpec(.streams) { controller, items in
                
                
                //Clean up the streams, remove streams without channel and feed identifiers.  (We can't build the relational data on the stream for filtering without these)
                let streams: [IPStream] = items.filter( { $0.channelId != nil && $0.feedId != nil })
                
                
                let _indexed: [String: IPStream] = streams.reduce(into: [:]) { result, item in
                    // Note: Can force unwrap channelId here because of the filtering above.
                    result[item.channelId!] = item
                }
                controller.indexedStreams = _indexed
            },
            LoadSpec(.channels) { controller, items in controller.channels = items },
            LoadSpec(.countries) { controller, items in controller.countries = items },
            LoadSpec(.categories) { controller, items in controller.categories = items },
            LoadSpec(.feeds) { controller, items in controller.feeds = items },
            LoadSpec<IPLogo>(.logos) { controller, items in
                let _indexedLogos: [ChannelId: URL] = items.reduce(into: [:]) { result, logo in
                    result[logo.channelId] = logo.url
                }
                controller.indexedLogos = _indexedLogos
            }
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
        
        for channelId in indexedLogos.keys {
            indexedStreams[channelId]?.logoURL = indexedLogos[channelId]
        }
        
        source.summary.finishedAt = Date()
        logDebug("IPTV channel discovery completed. 🏁")
        return source.summary
    }
}

