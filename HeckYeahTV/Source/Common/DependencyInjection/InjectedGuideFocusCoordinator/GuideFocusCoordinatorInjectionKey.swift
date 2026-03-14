//
//  GuideFocusCoordinatorInjectionKey.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 3/14/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

private struct GuideFocusCoordinatorKey: InjectionKey {
    @MainActor static var currentValue: GuideFocusCoordinator = GuideFocusCoordinator()
}

extension InjectedValues {
    var guideFocusCoordinator: GuideFocusCoordinator {
        get { Self[GuideFocusCoordinatorKey.self] }
        set { Self[GuideFocusCoordinatorKey.self] = newValue }
    }
}
