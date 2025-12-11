//
//  SwiftDataControllable.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/10/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftData

@MainActor
protocol SwiftDataControllable: ChannelFilterable {
    
    var guideChannelMap: ChannelMap { get }
    
    func toggleFavorite(for channelId: ChannelId)
    
    func isFavorite(channelId: ChannelId) -> Bool
    
    static func predicateBuilder(favoriteIds: Set<ChannelId>?,
                                 searchTerm: String?,
                                 countryCode: CountryCode,
                                 categoryId: CategoryId?) -> Predicate<IPTVChannel>
}
