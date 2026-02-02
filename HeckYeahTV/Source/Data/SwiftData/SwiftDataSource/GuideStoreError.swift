//
//  GuideStoreError.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/8/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

enum GuideStoreError: Error {
    case noChannelFoundForId(ChannelId)
}

extension GuideStoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
            case .noChannelFoundForId(let channelId):
                return "No channel found for id: \(channelId)"
        }
    }
}
