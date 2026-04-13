//
//  HomeRunControllerError.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/12/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

enum HomeRunControllerError: LocalizedError {
    case deviceOffline
    case invalidURL
    case noData
    case noDeviceAuth
    
    var errorDescription: String? {
        switch self {
            case .deviceOffline:
                return "The device could not be reached and appears to be offline."
            case .invalidURL:
                return "The URL could not be formed due to malformed data."
            case .noData:
                return "There was no data returned from a request, which was unexpected."
            case .noDeviceAuth:
                return "No device auth tokens available."
        }
    }
}
