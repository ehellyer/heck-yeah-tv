//
//  Program.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import Foundation

struct Program: Identifiable, Hashable {

    let id: String

    let title: String

    let startTime: Date

    let endTime: Date

    let description: String?
}

extension Program {
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var timeSlot: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}
