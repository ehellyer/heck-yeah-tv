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
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
    
    var timeSlot: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
    
    static func mockPrograms() -> [Program] {
        let now = Date()
        return [
            Program(id: UUID().uuidString,
                    title: "Mock Morning News",
                    startTime: now,
                    endTime: now.addingTimeInterval(1800),
                    description: "Mock Data"),
            Program(id: UUID().uuidString,
                    title: "Mock Weather Report",
                    startTime: now.addingTimeInterval(1800),
                    endTime: now.addingTimeInterval(3600),
                    description: "Mock Data"),
            Program(id: UUID().uuidString,
                    title: "Mock Talk Show",
                    startTime: now.addingTimeInterval(3600),
                    endTime: now.addingTimeInterval(5400),
                    description: "Mock Data"),
            Program(id: UUID().uuidString,
                    title: "Mock Yo mama's so fat!",
                    startTime: now.addingTimeInterval(5400),
                    endTime: now.addingTimeInterval(6700),
                    description: "Mock Data"),
            Program(id: UUID().uuidString,
                    title: "Mock Where's my money!",
                    startTime: now.addingTimeInterval(6700),
                    endTime: now.addingTimeInterval(7700),
                    description: "Mock Data"),
            Program(id: UUID().uuidString,
                    title: "Mock Man about town",
                    startTime: now.addingTimeInterval(8800),
                    endTime: now.addingTimeInterval(9900),
                    description: "Mock Data"),
            Program(id: UUID().uuidString,
                    title: "Mock Disney XD",
                    startTime: now.addingTimeInterval(8800),
                    endTime: now.addingTimeInterval(9900),
                    description: "Mock Data")
        ]
    }
}
