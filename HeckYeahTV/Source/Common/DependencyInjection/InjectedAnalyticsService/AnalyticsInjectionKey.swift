//
//  AnalyticsInjectionKey.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/17/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

private struct AnalyticsServiceKey: InjectionKey {
    static var currentValue: AnalyticsService = FirebaseAnalyticsService(debugLogging: true)
}

extension InjectedValues {
    var analytics: AnalyticsService {
        get { Self[AnalyticsServiceKey.self] }
        set { Self[AnalyticsServiceKey.self] = newValue }
    }
}
