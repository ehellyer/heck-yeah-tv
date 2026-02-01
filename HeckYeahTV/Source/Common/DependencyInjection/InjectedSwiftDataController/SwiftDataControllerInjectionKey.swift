//
//  SwiftDataControllerInjectionKey.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/9/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

private struct SwiftDataControllerInjectionKey: InjectionKey {
    @MainActor
    static var currentValue: SwiftDataProvider = SwiftDataController()
//    static var currentValue: SwiftDataProvider = MockSwiftDataController()
}

extension InjectedValues {
    var swiftDataController: SwiftDataProvider {
        get { Self[SwiftDataControllerInjectionKey.self] }
        set { Self[SwiftDataControllerInjectionKey.self] = newValue }
    }
}
