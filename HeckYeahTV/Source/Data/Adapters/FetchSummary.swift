//
//  FetchSummary.swift
//  iOS_HeckYeahTV
//
//  Created by Ed Hellyer on 8/28/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation
import SwiftUI

struct FetchSummary {
    @State var successes: [URL: Int] = [:]
    @State var failures: [URL: Error] = [:]
    var startedAt = Date()
    var finishedAt: Date = .distantPast
    var duration: TimeInterval {
        finishedAt.timeIntervalSince(startedAt)
    }
    
    func mergeSummary(_ summary: FetchSummary) {
        self.successes.merge(summary.successes) { (_, new) in new }
        self.failures.merge(summary.failures) { (_, new) in new }
    }
}
