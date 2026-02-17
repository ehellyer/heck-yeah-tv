//
//  LocalNetworkAuthorization.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/16/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation
import Network

/// The current Local Network permission status for this app.
enum LocalNetworkAuthorizationStatus: Int {
    /// The user has not yet been asked for permission.
    case notDetermined = 1
    /// The user granted permission.
    case granted = 2
    /// The user denied permission.
    case denied = 3
}

/// Triggers and reports the OS Local Network permission alert.
///
/// Uses the NWBrowser + NWListener technique recommended by Apple (TN3179):
/// a listener advertises a temporary Bonjour service on the local device, and
/// a browser looks for it. When the browser finds the listener, permission is
/// confirmed as granted. If the OS returns a PolicyDenied DNS error, permission
/// is denied. This removes any reliance on timeouts for the granted state.
///
/// Requires Info.plist entries:
///   - NSLocalNetworkUsageDescription
///   - NSBonjourServices containing "_preflight_check._tcp"
///
/// Usage:
/// ```swift
/// let manager = LocalNetworkAuthorization()
/// let status = await manager.requestAuthorization()
/// ```
@Observable
final class LocalNetworkAuthorization {
    
    /// The current authorization status. Updated after `requestAuthorization()` completes.
    private(set) var status: LocalNetworkAuthorizationStatus = .notDetermined
    
    // The dedicated preflight service type must match an entry in NSBonjourServices.
    // Using a separate type prevents interference with real app networking.
    private let serviceType = "_preflight_check._tcp"
    
    private var browser: NWBrowser?
    private var listener: NWListener?
    
    /// Triggers the OS Local Network permission alert on first call and returns
    /// the resulting status. Safe to call multiple times — subsequent calls
    /// reflect the persisted OS decision without showing the alert again.
    @discardableResult
    func requestAuthorization() async -> LocalNetworkAuthorizationStatus {
        let result = await checkAuthorization()
        status = result
        return result
    }
    
    // MARK: - Private
    
    private func checkAuthorization() async -> LocalNetworkAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            let token = OnceToken()
            
            do {
                // Start a listener that advertises a temporary local service.
                // The browser finding this service is confirmation of granted access.
                let listenerParams = NWParameters(tls: .none, tcp: NWProtocolTCP.Options())
                let listener = try NWListener(using: listenerParams)
                listener.service = NWListener.Service(
                    name: UUID().uuidString,
                    type: serviceType
                )
                // Required — NWListener won't start without a connection handler.
                listener.newConnectionHandler = { _ in }
                self.listener = listener
                listener.start(queue: .main)
                
                // Start a browser looking for the listener's service type.
                let browserParams = NWParameters()
                browserParams.includePeerToPeer = true
                let browser = NWBrowser(
                    for: .bonjour(type: serviceType, domain: nil),
                    using: browserParams
                )
                self.browser = browser
                
                browser.browseResultsChangedHandler = { results, _ in
                    // Any result means the browser found our listener — permission granted.
                    guard !results.isEmpty else { return }
                    Task { @MainActor in
                        self.stopAll()
                        token.resume(continuation, returning: .granted)
                    }
                }
                
                browser.stateUpdateHandler = { state in
                    switch state {
                        case .failed(let error):
                            let isDenied = self.isPermissionDeniedError(error)
                            Task { @MainActor in
                                self.stopAll()
                                token.resume(continuation, returning: isDenied ? .denied : .granted)
                            }
                            
                        case .waiting(let error):
                            // kDNSServiceErr_PolicyDenied (-65570) signals Local Network denial.
                            guard self.isPermissionDeniedError(error) else { return }
                            Task { @MainActor in
                                self.stopAll()
                                token.resume(continuation, returning: .denied)
                            }
                            
                        case .cancelled:
                            // Fired after stopAll() — OnceToken ensures only first resume wins.
                            token.resume(continuation, returning: .denied)
                            
                        default:
                            break
                    }
                }
                
                browser.start(queue: .main)
                
            } catch {
                token.resume(continuation, returning: .denied)
            }
        }
    }
    
    private func stopAll() {
        browser?.cancel()
        browser = nil
        listener?.cancel()
        listener = nil
    }
    
    /// Returns true if the error is the OS Local Network permission denial signal.
    private nonisolated func isPermissionDeniedError(_ error: NWError) -> Bool {
        // kDNSServiceErr_PolicyDenied = -65570
        if case .dns(let code) = error, code == -65570 {
            return true
        }
        return false
    }
}

// MARK: - OnceToken

/// Ensures a `CheckedContinuation` is resumed exactly once.
private final class OnceToken: @unchecked Sendable {
    
    private let lock = NSLock()
    private nonisolated(unsafe) var hasResumed = false
    
    nonisolated init() {}
    
    nonisolated func resume(_ continuation: CheckedContinuation<LocalNetworkAuthorizationStatus, Never>,
                            returning value: LocalNetworkAuthorizationStatus) {
        lock.lock()
        defer { lock.unlock() }
        guard !hasResumed else { return }
        hasResumed = true
        continuation.resume(returning: value)
    }
}
