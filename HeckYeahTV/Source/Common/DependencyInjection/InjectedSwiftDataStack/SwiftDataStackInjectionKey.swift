//
//  SwiftDataStackInjectionKey.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/31/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

private struct SwiftDataStackInjectionKey: InjectionKey {
    @MainActor
    static var currentValue: SwiftDataStackProvider = SwiftDataStack.shared
//    static var currentValue: SwiftDataStackProvider = MockSwiftDataStack()
}

extension InjectedValues {
    var swiftDataStack: SwiftDataStackProvider {
        get { Self[SwiftDataStackInjectionKey.self] }
        set { Self[SwiftDataStackInjectionKey.self] = newValue }
    }
}
