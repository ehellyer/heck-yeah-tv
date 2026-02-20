//
//  DebugLogger.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 10/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

// ***************************************************************************************************************************
// ***************************************************************************************************************************
//
// TODO:    This is a temporary implementation of DebugLogger that primarily is for printing to the console window for the developer (Ed).
//          Future versions will write all messages to a cycling file that can be used for production runtime analysis.
//
//          WARNING: NEVER LOG UNPROTECTED SENSITIVE INFORMATION (I never do this.  - Ed.  🤥)
//
// ***************************************************************************************************************************
// ***************************************************************************************************************************

import Foundation


internal func logDebug<T>(_ object: @autoclosure () -> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DebugLogger.shared.log(.debug, object(), file, function, line)
}

internal func logInformation<T>(_ object: @autoclosure () -> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DebugLogger.shared.log(.information, object(), file, function, line)
}

internal func logWarning<T>(_ object: @autoclosure () -> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DebugLogger.shared.log(.warning, object(), file, function, line)
}

internal func logError<T>(_ object: @autoclosure () -> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) {
    DebugLogger.shared.log(.error, object(), file, function, line)
}

internal func logFatal<T>(_ object: @autoclosure () -> T, file: StaticString = #file, function: StaticString = #function, line: UInt = #line) -> Never {
    DebugLogger.shared.log(.fatal, object(), file, function, line)
    let message = String(reflecting: object())
    fatalError(message)
}

class DebugLogger {
    
    nonisolated(unsafe) static let shared = DebugLogger()
    
    /// Describes the level of the log event.
    enum Level: Int {
        case debug = 1
        case information = 2
        case warning = 3
        case error = 4
        case fatal = 5
        
        /// Returns the en-US name of the log level.
        var name: String {
            switch self {
                case .debug: return "Debug"
                case .information: return "Info"
                case .warning: return "Warning"
                case .error: return "Error"
                case .fatal: return "Fatal"
            }
        }
        
        /// Returns the emoji for the level.
        var emoji: String {
            switch self {
                case .debug: return "🔧"
                case .information: return "📊"
                case .warning: return "⚠️"
                case .error: return "🐞"
                case .fatal: return "🧨"
            }
        }
    }
    
    private init() { }
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
    
    //MARK: - FilePrivate API - The glue between app scoped logging functions and instance logging function.
    
    fileprivate func log<T>(_ level: DebugLogger.Level, _ object: @autoclosure () -> T, _ file: StaticString, _ function: StaticString, _ line: UInt) {
        
        let value = object()
        let queue = Thread.isMainThread ? "M" : "B"
        
        let fileName = URL(fileURLWithPath: file.description).lastPathComponent
        let timeStr = self.dateFormatter.string(from: Date())
        let message = String(reflecting: value)
        let emoji = level.emoji

#if DEBUG
        let consoleLogString = "\(timeStr) l:\(emoji) q:\(queue) s:\(fileName) \(function) \(line) m:\(message)"
        print(consoleLogString)
#endif
        //TODO: Log to cycling offline local file for post crash analytics package.
    }
}
