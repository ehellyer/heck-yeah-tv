//
//  FetchDescriptor+Extension.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/24/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftData

extension FetchDescriptor {

    /// Sets the fetch limit on this descriptor.
    ///
    /// Values of `nil` or less than 1 clear the fetch limit.
    mutating func setFetchLimit(_ fetchLimit: Int?) {
        if let fetchLimit, fetchLimit > 0 {
            self.fetchLimit = fetchLimit
        } else {
            self.fetchLimit = nil
        }
    }
}
