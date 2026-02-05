//
//  ChannelProgramDateFormatter.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/1/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// Utility for formatting time slots (start time - end time) efficiently across UIKit, AppKit, and SwiftUI.
///
/// This class uses a single shared `DateFormatter` instance to minimize allocation overhead,
/// making it suitable for use in high-frequency rendering scenarios like list/grid views.
///
/// Example usage:
/// ```swift
/// let timeSlot = ChannelProgramDateFormatter.format(startTime: program.startTime, endTime: program.endTime)
/// // Returns: "9:00 AM - 10:00 AM"
/// ```
enum ChannelProgramDateFormatter {

    
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter
    }()
    
    /// Shared date formatter for time slot strings. Reused to avoid repeated alloc/init.
    /// Thread-safe when used from the main thread (which is typical for UI formatting).
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private static let airdateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Formats a time slot as "start - end" (e.g., "9:00 AM - 10:00 AM")
    ///
    /// - Parameters:
    ///   - startTime: The start time of the program
    ///   - endTime: The end time of the program
    /// - Returns: A formatted string representing the time slot
    static func format(startTime: Date, endTime: Date) -> String {
        
        let startTimeString = timeFormatter.string(from: startTime)
        let endTimeString = timeFormatter.string(from: endTime)
        return "\(startTimeString) - \(endTimeString)"
    }
    
    static func dayTimeFormat(startTime: Date, endTime: Date) -> String {
        
        let startTimeString = timeFormatter.string(from: startTime)
        let endTimeString = timeFormatter.string(from: endTime)
        return "\(ChannelProgramDateFormatter.dayFormatter.string(from: startTime)), \(startTimeString) - \(endTimeString)"
    }
    
    static func originalAirDateFormat(originalAirDate: Date) -> String {
        ChannelProgramDateFormatter.airdateFormatter.string(from: originalAirDate)
    }
    
}

// MARK: - ChannelProgram Extension

extension ChannelProgram {
    
    var formattedDayTimeSlot: String {
        ChannelProgramDateFormatter.dayTimeFormat(startTime: startTime, endTime: endTime)
    }
    
    /// Returns a formatted time slot string for this program
    var formattedTimeSlot: String {
        ChannelProgramDateFormatter.format(startTime: startTime, endTime: endTime)
    }
    
    var formattedOriginalAirDate: String? {
        guard let originalAirDate else {
            return nil
        }
        return ChannelProgramDateFormatter.originalAirDateFormat(originalAirDate: originalAirDate)
    }
}
