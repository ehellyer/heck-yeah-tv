//
//  AnalyticsService.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/17/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import FirebaseAnalytics

/// Protocol defining analytics capabilities.
/// Allows for easy mocking in tests and previews.
protocol AnalyticsService: Sendable {
    /// Logs a custom analytics event
    func log(_ event: AnalyticsEvent)
    
    /// Sets a user property that persists across sessions
    func setUserProperty(_ value: String?, forName: String)
    
    /// Sets a user ID for tracking (optional - be careful with privacy)
    func setUserId(_ userId: String?)
    
    /// Enables or disables analytics collection
    func setAnalyticsEnabled(_ enabled: Bool)
}

/// Firebase implementation of AnalyticsService
/// Uses @unchecked Sendable because Firebase Analytics is thread-safe
final class FirebaseAnalyticsService: AnalyticsService, @unchecked Sendable {
    
    private let isDebugLoggingEnabled: Bool
    
    init(debugLogging: Bool = false) {
        self.isDebugLoggingEnabled = debugLogging
    }
    
    func log(_ event: AnalyticsEvent) {
        #if DEBUG
        if isDebugLoggingEnabled {
            logDebug("📊 Analytics: \(event.name) - \(event.parameters)")
        }
        #endif
        
        Analytics.logEvent(event.name, parameters: event.parameters)
    }
    
    func setUserProperty(_ value: String?, forName: String) {
        Analytics.setUserProperty(value, forName: forName)
        
        #if DEBUG
        if isDebugLoggingEnabled {
            logDebug("📊 User Property: \(forName) = \(value ?? "nil")")
        }
        #endif
    }
    
    func setUserId(_ userId: String?) {
        Analytics.setUserID(userId)
        
        #if DEBUG
        if isDebugLoggingEnabled {
            logDebug("📊 User ID: \(userId ?? "nil")")
        }
        #endif
    }
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        Analytics.setAnalyticsCollectionEnabled(enabled)
        
        #if DEBUG
        if isDebugLoggingEnabled {
            logDebug("📊 Analytics Enabled: \(enabled)")
        }
        #endif
    }
}

/// Mock implementation for previews and testing
final class MockAnalyticsService: AnalyticsService, @unchecked Sendable {
    
    private let lock = NSLock()
    private var _loggedEvents: [AnalyticsEvent] = []
    private var _userProperties: [String: String?] = [:]
    private var _userId: String?
    private var _isEnabled: Bool = true
    
    func getLoggedEvents() -> [AnalyticsEvent] {
        lock.withLock { _loggedEvents }
    }
    
    func getUserProperties() -> [String: String?] {
        lock.withLock { _userProperties }
    }
    
    func getUserId() -> String? {
        lock.withLock { _userId }
    }
    
    func getIsEnabled() -> Bool {
        lock.withLock { _isEnabled }
    }
    
    func log(_ event: AnalyticsEvent) {
        lock.withLock {
            _loggedEvents.append(event)
        }
        print("🧪 Mock Analytics: \(event.name) - \(event.parameters)")
    }
    
    func setUserProperty(_ value: String?, forName: String) {
        lock.withLock {
            _userProperties[forName] = value
        }
    }
    
    func setUserId(_ userId: String?) {
        lock.withLock {
            _userId = userId
        }
    }
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        lock.withLock {
            _isEnabled = enabled
        }
    }
    
    func reset() {
        lock.withLock {
            _loggedEvents.removeAll()
            _userProperties.removeAll()
            _userId = nil
            _isEnabled = true
        }
    }
}
