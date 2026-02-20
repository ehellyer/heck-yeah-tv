//
//  SwiftDataProvider.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
protocol SwiftDataProvider: ChannelManageable, ChannelFilterable, SwiftDataStackProvider { }
