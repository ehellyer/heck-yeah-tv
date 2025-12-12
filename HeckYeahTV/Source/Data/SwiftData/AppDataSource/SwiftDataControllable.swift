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
    
    static func predicateBuilder(showFavoritesOnly: Bool,
                                 searchTerm: String?,
                                 countryCode: CountryCode,
                                 categoryId: CategoryId?) -> Predicate<IPTVChannel>
}
