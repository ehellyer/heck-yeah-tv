//
//  BundleEntry+NewBundleEntryId.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/23/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

extension BundleEntry {
    static func newBundleEntryId(channelBundleId: ChannelBundleId, channelId: ChannelId) -> BundleEntryId {
        return String.stableHashHex(channelBundleId, channelId)
    }
}
