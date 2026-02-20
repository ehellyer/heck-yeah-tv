//
//  HDHomeRunChannelGuide.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

/// HDHomeRunChannelGuide - Represents airing information for channel suitable for displaying in a Live TV guide.  Returned as an array of `HDHomeRunChannelGuide`.
///
/// e.g. [https://api.hdhomerun.com/api/guide?DeviceAuth=B3CwagB78qp9B8kjcT_UYjRL&Start=&Duration=10&Channel=](https://api.hdhomerun.com/api/guide?DeviceAuth=B3CwagB78qp9B8kjcT_UYjRL&Start=&Duration=10&Channel=) -> `[HDHomeRunChannelGuide]`
struct HDHomeRunChannelGuide: JSONSerializable, Equatable  {
    
    /// The guide number assigned by HDHomeRun
    let guideNumber: String
    
    /// The channel name.
    let guideName: String
    
    /// The affiliated broadcast corporation, studio, or corporation.
    let affiliate: String?
    
    /// The channel image logo
    let logoURL: URL?
    
    /// The scheduled programs for the channel.
    let programs: [HDHomeRunProgram]
}

//MARK: - JSONSerializable customization

extension HDHomeRunChannelGuide {
    
    enum CodingKeys: String, CodingKey {
        case guideNumber = "GuideNumber"
        case guideName = "GuideName"
        case affiliate = "Affiliate"
        case logoURL = "ImageURL"
        case programs = "Guide"
    }
}
