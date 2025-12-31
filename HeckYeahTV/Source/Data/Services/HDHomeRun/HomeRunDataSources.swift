//
//  HomeRunDataSources.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

struct HomeRunDataSources {
    struct Tuner {
        static let discoveryURL = URL(string: "https://api.hdhomerun.com/discover")!
    }
    struct TVListings {
        static let guideURL = URL(string: "https://api.hdhomerun.com/api/guide")!
    }
}
