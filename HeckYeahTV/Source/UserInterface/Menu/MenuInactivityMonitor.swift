//
//  MenuInactivityMonitor.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/23/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
import UIKit.UIGestureRecognizerSubclass
#elseif canImport(AppKit)
import AppKit
#endif

/// Automatically dismisses the app menu (and any screen it is hosting) after a period of user inactivity.
///
/// The idle delay is `menuAutoDismissNS`.  User activity is reported by `MenuActivityHook`, which watches
/// for input app-wide, so no per-screen code is needed.
///
/// Auto-dismiss is suspended (the countdown is re-armed instead) while:
/// - A text field is being edited.
/// - There are no channels in the guide (boot presents the Settings screen in this case).
/// - An IPTV or HDHomeRun reload is running.
@MainActor
final class MenuInactivityMonitor {

    /// Starts (or restarts) the inactivity countdown.  Called when the app menu is presented.
    func start() {
        registerActivity()
        guard timerTask == nil else { return }
        timerTask = Task { @MainActor [weak self] in
            await self?.runCountdown()
        }
    }

    /// Stops the inactivity countdown.  Called when the app menu is dismissed.
    func stop() {
        timerTask?.cancel()
        timerTask = nil
    }

    /// Records user activity, pushing the auto-dismiss deadline out by the full delay.
    ///
    /// Only stamps the time, so it is cheap to call for high frequency events such as mouse moves.
    func registerActivity() {
        lastActivity = .now
    }

    /// Records whether a button or touch is currently held down.
    ///
    /// Held input only produces an event when it begins and ends (e.g. holding an arrow to auto-scroll the guide), so the
    /// countdown is suspended while input is held, and restarts when it is released.
    func setInputHeld(_ isHeld: Bool) {
        isInputHeld = isHeld
        registerActivity()
    }

    //MARK: - Private API

    private var isInputHeld: Bool = false
    private var lastActivity: ContinuousClock.Instant = .now
    private var timerTask: Task<Void, Never>?
    private let delay: Duration = .nanoseconds(Int64(menuAutoDismissNS))

    private func runCountdown() async {
        while not(Task.isCancelled) {
            // Sleep until the current deadline.  Activity during the sleep moves the deadline out, so check again on wake.
            try? await Task.sleep(until: lastActivity.advanced(by: delay), clock: .continuous)
            guard not(Task.isCancelled) else { return }

            if lastActivity.advanced(by: delay) > .now {
                continue
            }

            if isSuspended {
                // Re-arm and check again after another full delay.
                registerActivity()
                continue
            }

            dismissMenu()
            timerTask = nil
            return
        }
    }

    private func dismissMenu() {
        var appState: AppStateProvider = InjectedValues[\.sharedAppState]
        logDebug("App menu inactive, auto-dismissing.")
        withAnimation {
            appState.showProgramDetailCarousel = nil
            appState.showAppMenu = false
        }
    }

    private var isSuspended: Bool {
        if isInputHeld {
            return true
        }

        let appState: AppStateProvider = InjectedValues[\.sharedAppState]
        if appState.isReloadingIPTV || appState.isReloadingHomeRun {
            return true
        }

        let swiftDataController = InjectedValues[\.swiftDataController]
        if swiftDataController.channelBundleMap.channelIds.isEmpty {
            return true
        }

        return isEditingText
    }

    private var isEditingText: Bool {
#if canImport(UIKit)
        let firstResponder = UIResponder.currentFirstResponder
        return firstResponder is UITextField || firstResponder is UITextView
#elseif canImport(AppKit)
        // While editing, the first responder of the key window is the field editor (an NSText).
        return NSApp.keyWindow?.firstResponder is NSText
#endif
    }
}

//MARK: - App-wide activity hook

/// A hidden view that reports user input app-wide to a `MenuInactivityMonitor`.
///
/// - iOS/tvOS: Installs a passive gesture recognizer on the window that observes touches (including Siri Remote swipes)
///   and remote presses without ever recognizing, so it does not interfere with any other gestures.  On tvOS, focus
///   moves are also observed.
/// - macOS: Installs a local event monitor for mouse, keyboard and scroll events.  Events are passed through unchanged.
struct MenuActivityHook: CrossPlatformRepresentable {

    let monitor: MenuInactivityMonitor

    func makeView(context: Context) -> PlatformView {
        let view = ActivityHookView()
        view.monitor = monitor
        return view
    }

    func updateView(_ view: PlatformView, context: Context) {
        (view as? ActivityHookView)?.monitor = monitor
    }

    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) {
        (view as? ActivityHookView)?.uninstall()
    }
}

#if canImport(UIKit)

private final class ActivityHookView: UIView {

    weak var monitor: MenuInactivityMonitor?

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        uninstall()
        guard let window else { return }

        let recognizer = ActivityGestureRecognizer(target: nil, action: nil)
        recognizer.onActivity = { [weak self] in
            self?.monitor?.registerActivity()
        }
        recognizer.onInputHeldChanged = { [weak self] isHeld in
            self?.monitor?.setInputHeld(isHeld)
        }
        window.addGestureRecognizer(recognizer)
        activityRecognizer = recognizer

#if os(tvOS)
        // Swipes on the Siri Remote move focus, treat every focus update as activity.
        focusObserverTask = Task { @MainActor [weak self] in
            let notifications = NotificationCenter.default.notifications(named: UIFocusSystem.didUpdateNotification)
            for await _ in notifications {
                guard not(Task.isCancelled) else { return }
                self?.monitor?.registerActivity()
            }
        }
#endif
    }

    func uninstall() {
        if let activityRecognizer {
            activityRecognizer.view?.removeGestureRecognizer(activityRecognizer)
            monitor?.setInputHeld(false)
        }
        activityRecognizer = nil
        focusObserverTask?.cancel()
        focusObserverTask = nil
    }

    private var activityRecognizer: ActivityGestureRecognizer?
    private var focusObserverTask: Task<Void, Never>?
}

/// A gesture recognizer that never recognizes.  It only observes touches and presses and reports them as activity.
private final class ActivityGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

    var onActivity: (() -> Void)?

    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
        // Include indirect touches so swipes on the Siri Remote touch surface are observed.
        allowedTouchTypes = [UITouch.TouchType.direct, .indirect, .indirectPointer].map { NSNumber(value: $0.rawValue) }
        // The default is `.select` only, which misses the directional presses used to navigate (remote d-pad, keyboard arrows in the simulator).
        var pressTypes: [UIPress.PressType] = [.upArrow, .downArrow, .leftArrow, .rightArrow, .select, .menu, .playPause]
#if os(tvOS)
        pressTypes.append(contentsOf: [.pageUp, .pageDown])
#endif
        allowedPressTypes = pressTypes.map { NSNumber(value: $0.rawValue) }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        heldTouches.formUnion(touches)
        updateHeldState()
        onActivity?()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        onActivity?()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        heldTouches.subtract(touches)
        endIfNoInputHeld()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        heldTouches.subtract(touches)
        endIfNoInputHeld()
    }

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        heldPresses.formUnion(presses)
        updateHeldState()
        onActivity?()
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        heldPresses.subtract(presses)
        endIfNoInputHeld()
    }

    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent) {
        heldPresses.subtract(presses)
        endIfNoInputHeld()
    }

    override func reset() {
        super.reset()
        // Safety net: UIKit resets the recognizer once an event sequence is over, so never leave the held state stuck on.
        heldTouches.removeAll()
        heldPresses.removeAll()
        updateHeldState()
    }

    //MARK: - Held input tracking

    /// Called when held input starts (`true`) or all held input is released (`false`).
    var onInputHeldChanged: ((Bool) -> Void)?

    private var heldTouches: Set<UITouch> = []
    private var heldPresses: Set<UIPress> = []
    private var isInputHeld: Bool = false

    private func updateHeldState() {
        let isHeld = not(heldTouches.isEmpty) || not(heldPresses.isEmpty)
        guard isHeld != isInputHeld else { return }
        isInputHeld = isHeld
        onInputHeldChanged?(isHeld)
    }

    /// Fails the recognizer only once all input is released.  Failing earlier would stop delivery of the remaining
    /// end events, leaving the held state stuck on.
    private func endIfNoInputHeld() {
        updateHeldState()
        if not(isInputHeld) {
            state = .failed
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

private extension UIResponder {

    @MainActor private static weak var foundFirstResponder: UIResponder?

    /// The current first responder, found by sending an action to a nil target, which UIKit delivers to the first responder.
    static var currentFirstResponder: UIResponder? {
        foundFirstResponder = nil
        UIApplication.shared.sendAction(#selector(captureFirstResponder), to: nil, from: nil, for: nil)
        return foundFirstResponder
    }

    @objc func captureFirstResponder() {
        UIResponder.foundFirstResponder = self
    }
}

#elseif canImport(AppKit)

private final class ActivityHookView: NSView {

    weak var monitor: MenuInactivityMonitor?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        uninstall()
        guard let window else { return }

        // Mouse moved events are only delivered when the window accepts them.
        window.acceptsMouseMovedEvents = true

        let eventTypes: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .rightMouseDown, .otherMouseDown, .leftMouseDragged, .keyDown, .scrollWheel]
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventTypes) { [weak self] event in
            MainActor.assumeIsolated {
                self?.monitor?.registerActivity()
            }
            return event
        }
    }

    // Never intercept mouse events.
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }

    func uninstall() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
        eventMonitor = nil
    }

    private var eventMonitor: Any?
}

#endif
