//
//  ChannelSource.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Hellfire

enum ChannelSource: String, Hashable, Sendable, JSONSerializable {
    case ipStream
    case homeRunTuner
}
