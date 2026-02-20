//
//  SharedAppStateInjectionKey.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/31/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

private struct SharedAppStateInjectionKey: InjectionKey {
    @MainActor
    static var currentValue: AppStateProvider = SharedAppState.shared
//    static var currentValue: AppStateProvider = MockSharedAppState()
}

extension InjectedValues {
    var sharedAppState: AppStateProvider {
        get { Self[SharedAppStateInjectionKey.self] }
        set { Self[SharedAppStateInjectionKey.self] = newValue }
    }
}
