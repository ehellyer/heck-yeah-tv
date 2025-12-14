//
//  ChannelSourceType.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/30/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

enum ChannelSourceType: String, Hashable, Sendable, JSONSerializable {
    case ipStream = "ipStream"
    case homeRunTuner = "homeRunTuner"
}
