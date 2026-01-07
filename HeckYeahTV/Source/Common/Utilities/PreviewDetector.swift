//
//  PreviewDetector.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/3/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

enum PreviewDetector {
    static var isRunningInPreview: Bool {
#if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
#else
        return false
#endif
    }
}

