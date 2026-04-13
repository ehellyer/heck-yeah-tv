//
//  Watchdog.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 4/7/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import Foundation

/// A loyal watchdog that keeps an eye on things and barks (calls your action) at regular intervals.
/// Unlike real dogs, this one doesn't need walks, food, or complain about not getting enough attention.
/// Just set it loose and it'll dutifully check on things until you tell it to stop.
///
/// Perfect for monitoring tasks that might take too long, like waiting for VLC to decide
/// whether it feels like playing a stream today or not.
actor Watchdog {

    deinit {
        task?.cancel()
        task = nil
    }
    
    /// Creates a watchdog with a configurable patrol interval.
    /// - Parameter loopTime: How often the watchdog checks in. Default: 1 second.
    ///   (That's like 7 seconds in dog years, but we don't judge.)
    init(loopTime: Duration = Duration.seconds(1)) {
        self.loopTime = loopTime
    }
    
    private var loopTime: Duration
    private var task: Task<Void, Never>?

    /// Unleashes the watchdog! It'll keep calling your action until you tell it to stop,
    /// or until the action returns `false` (the watchdog's way of saying "I'm done here").
    ///
    /// - Parameter action: Your inspection routine. Return `true` to keep the watchdog running,
    ///   or `false` to give it a well-deserved break.
    ///
    /// Example:
    /// ```swift
    /// let watchdog = Watchdog(loopTime: .seconds(10))
    /// await watchdog.start {
    ///     let isStillTryingToPlay = await checkIfVLCIsBeingDifficult()
    ///     return isStillTryingToPlay  // Keep watching if VLC is still struggling
    /// }
    /// ```
    func start(action: @escaping () async -> Bool) {
        task?.cancel()
        task = Task(name: "heckyeahtv-playback-watchdog-task") { [weak self] in
            logDebug("Playback watchdog 🐕 - monitoring started.")
            while !Task.isCancelled {
                
                guard let self else { break }
                
                let shouldContinue = await action()
                
                // The watchdog has decided its work here is done. Time for a nap. 🐕💤
                if !shouldContinue {
                    logDebug("Playback watchdog 🐕 - monitoring completed and exiting to stop.")
                    break
                }
                
                // Snooze until next patrol
                try? await Task.sleep(for: self.loopTime)
            }
        }
    }

    /// Tells the watchdog to stop patrolling. Good dog! 🦴
    /// (Call this from outside the watchdog loop when you're ready to call it a day.)
    func stop() {
        logDebug("Playback watchdog 🐕 - monitoring called to stop.")
        task?.cancel()
        task = nil
    }
}
