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
        
    ///MARK: - Internal API - Fetch stuff
    
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

    func fetchList<T: JSONSerializable>(url: URL) async throws -> T {
        let request = NetworkRequest(url: url,
                                     method: .get,
                                     headers: [HTTPHeader.defaultUserAgent,
                                               HTTPHeader(name: "Accept-Encoding", value: "application/json"),
                                               HTTPHeader(name: "connection", value: "close")]) // keep-alive off
        
        let response = try await self.sessionInterface.execute(request)
        let jsonObject = try T.initialize(jsonData: response.body)
        return jsonObject
    }
    
    /// Fetches all endpoints concurrently and returns a summary of successes/failures.
    /// Does not throw; failed endpoints are recorded in `FetchSummary.failures`.
    func fetchAll() async -> IPTVFetchSummary {
        var summary = IPTVFetchSummary()
        summary.startedAt = Date()
        
        let specs: [AnyLoadSpec] = [
            LoadSpec(.channels, keyPath: \.channels),
            LoadSpec(.streams, keyPath: \.streams)
        ]
        
        // Run everything concurrently; each task returns (endpoint, Result<count, error>)
        await withTaskGroup(of: (IPTVFetchSummary.Endpoint, Result<Int, Error>).self) { group in
            for spec in specs {
                group.addTask { [weak self] in
                    guard let self else { return (spec.endpoint, .failure(CancellationError())) }
                    do {
                        let count = try await spec.load(into: self)
                        return (spec.endpoint, .success(count))
                    } catch {
                        return (spec.endpoint, .failure(error))
                    }
                }
            }
            
            // Aggregate results on the main actor (this method is @MainActor)
            for await (endpoint, result) in group {
                switch result {
                    case .success(let count):
                        summary.successes[endpoint] = count
                    case .failure(let error):
                        summary.failures[endpoint] = error
                }
            }
        }
        
        summary.finishedAt = Date()
        return summary
    }
}
