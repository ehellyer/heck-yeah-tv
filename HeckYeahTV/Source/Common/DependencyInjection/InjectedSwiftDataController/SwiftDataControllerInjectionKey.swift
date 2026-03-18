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
    static var currentValue: BaseSwiftDataController = SwiftDataController()
}

extension InjectedValues {
    var swiftDataController: BaseSwiftDataController {
        get { Self[SwiftDataControllerInjectionKey.self] }
        set { Self[SwiftDataControllerInjectionKey.self] = newValue }
    }
}
