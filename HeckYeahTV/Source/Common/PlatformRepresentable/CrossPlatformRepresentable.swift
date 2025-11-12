//
//  CrossPlatformRepresentable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

@MainActor
protocol CrossPlatformRepresentable: PlatformViewRepresentable {

    associatedtype Coordinator = Void
    
    func makeView(context: Context) -> PlatformView
    
    func updateView(_ view: PlatformView, context: Context)
    
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator)

    @available(iOS 16.0, tvOS 16.0, macOS 13.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, view: PlatformView, context: Context) -> CGSize
}

// Defaults for optional protocol implementation
extension CrossPlatformRepresentable {
    
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) {
        // No default implementation
    }
    
    @available(iOS 16.0, tvOS 16.0, macOS 13.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, view: PlatformView, context: Context) -> CGSize {
        // Default implementation returning CGSize.zero
        return .zero
    }
}

#if canImport(UIKit)
//MARK: - UIKit forwarding
extension CrossPlatformRepresentable where PlatformView == UIView {

    func makeUIView(context: Context) -> UIView {
        makeView(context: context)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        updateView(uiView, context: context)
    }
    
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        dismantleView(uiView, coordinator: coordinator)
    }
    
    @available(iOS 16.0, tvOS 16.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UIView, context: Context) -> CGSize {
        sizeThatFits(proposal, view: uiView, context: context)
    }
}
#endif

#if canImport(AppKit) //&& !targetEnvironment(macCatalyst)
//MARK: - AppKit forwarding
extension CrossPlatformRepresentable where PlatformView == NSView {
    
    func makeNSView(context: Context) -> NSView {
        makeView(context: context)
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        updateView(nsView, context: context)
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        dismantleView(nsView, coordinator: coordinator)
    }
    
    @available(macOS 13.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSView, context: Context) -> CGSize {
        sizeThatFits(proposal, view: nsView, context: context)
    }
}
#endif
