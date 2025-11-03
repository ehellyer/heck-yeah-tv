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
// TODO:  This is a temporary implementation that primarily is for printing to the console window for the developer.
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
    
    static let shared = DebugLogger()
    
    /// Describes the level of the log event.
    enum Level: Int {
        
        /// Messages logged at level `DebugLogger.Level.debug` __only appear in the console when the app is compiled as non-release configuration.__  This level of logging is
        /// used for general messages, tagging events, or other telemetry purposes.
        ///
        /// All messages to the log function are logged to the diagnostics log file that can be sent from the client to the
        /// server for remote diagnostics of the application.
        case debug = 1
        
        /// Messages logged at level `DebugLogger.Level.information` __only appear in the console when the app is compiled as non-release configuration.__  This level of logging is
        /// used for general messages, tagging events, or other telemetry purposes.
        ///
        /// All messages to the log function are logged to the diagnostics log file that can be sent from the client to the
        /// server for remote diagnostics of the application.
        case information = 2
        
        /// Messages logged at level `DebugLogger.Level.waring` __only appear in the console when the app is compiled as non-release configuration.__  This level of logging is
        /// used for warnings, such as unexpected states that are not error or fatal exceptions, .
        ///
        /// All messages to the log function are logged to the diagnostics log file that can be sent from the client to the
        /// server for remote diagnostics of the application.
        case warning = 3
        
        /// Messages logged at level `DebugLogger.Level.error` __will always be logged to the console.__  This level of logging is
        /// used for non-fatal runtime errors.
        ///
        /// All messages to the log function are logged to the diagnostics log file that can be sent from the client to the
        /// server for remote diagnostics of the application.
        case error = 4
        
        /// Messages logged at level `DebugLogger.Level.fatal` __will always be logged to the console.__  This level of logging is
        /// used for fatal runtime errors.  The application is terminated after logging at this level.
        ///
        /// All messages to the log function are logged to the diagnostics log file that can be sent from the client to the
        /// server for remote diagnostics of the application.
        case fatal = 5
        
        /// Returns the en-US name of the log level.
        var name: String {
            switch self {
                case .debug:
                    return "Debug"
                case .information:
                    return "Info"
                case .warning:
                    return "Warning"
                case .error:
                    return "Error"
                case .fatal:
                    return "Fatal"
            }
        }
        
        /// Returns the emoji for the level.
        var emoji: String {
            switch self {
                case .debug:
                    return "🔧"
                case .information:
                    return "📊"
                case .warning:
                    return "‼️"
                case .error:
                    return "🐛"
                case .fatal:
                    return "🧨"
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
        let consoleLogString = "\(timeStr) l:\(emoji)) q:\(queue) s:\(fileName) \(function) \(line) m:\(message)"
        print(consoleLogString)
#endif
        //TODO: Log to cycling offline local file for post crash analytics package.
    }
}
