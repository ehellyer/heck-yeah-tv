//
//  LoadSpec.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

protocol AnyLoadSpec {
    var endpoint: IPTVFetchSummary.Endpoint { get }
    func load(into controller: IPTVController) async throws -> Int
}

struct LoadSpec<T: JSONSerializable>: AnyLoadSpec {
    
    init(_ endpoint: IPTVFetchSummary.Endpoint, keyPath: ReferenceWritableKeyPath<IPTVController, [T]>) {
        self.endpoint = endpoint
        self.url = endpoint.url
        self.keyPath = keyPath
    }

    private let url: URL
    private let keyPath: ReferenceWritableKeyPath<IPTVController, [T]>

    let endpoint: IPTVFetchSummary.Endpoint
    
    /// Fetches, assigns to the controller property, and returns the number of items loaded.
    func load(into controller: IPTVController) async throws -> Int {
        let items: [T] = try await controller.fetchList(url: url)
        controller[keyPath: keyPath] = items
        return items.count
    }
}
