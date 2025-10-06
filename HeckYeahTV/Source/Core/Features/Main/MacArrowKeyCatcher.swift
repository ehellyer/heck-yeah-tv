//
//  MacArrowKeyCatcher.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/26/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

#if os(macOS)
import SwiftUI
import AppKit

/// A tiny NSView bridge that makes itself first responder and
/// calls `onArrow()` on arrow-key presses to re-show the guide.
struct MacArrowKeyCatcher: NSViewRepresentable {
    let onArrow: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let v = KeyCatcherView(onArrow: onArrow)
        DispatchQueue.main.async { v.window?.makeFirstResponder(v) }
        return v
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { nsView.window?.makeFirstResponder(nsView) }
    }
    
    final class KeyCatcherView: NSView {
        let onArrow: () -> Void
        init(onArrow: @escaping () -> Void) {
            self.onArrow = onArrow
            super.init(frame: .zero)
        }
        required init?(coder: NSCoder) { fatalError() }
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
                case 123, 124, 125, 126: // left, right, down, up
                    onArrow()
                default:
                    break
            }
        }
    }
}
#endif // os(macOS)
