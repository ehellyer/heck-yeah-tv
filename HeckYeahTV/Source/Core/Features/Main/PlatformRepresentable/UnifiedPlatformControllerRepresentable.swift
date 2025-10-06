//
//  UnifiedPlatformControllerRepresentable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/24/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

@MainActor
protocol UnifiedPlatformControllerRepresentable: PlatformViewControllerRepresentable {
    
    func makeViewController(context: Context) -> PlatformViewController
    
    func updateViewController(_ viewController: PlatformViewController, context: Context)
    
    static func dismantleViewController(_ viewController: PlatformViewController, coordinator: Coordinator)
}

#if canImport(UIKit)
//MARK: - UIKit forwarding
extension UnifiedPlatformControllerRepresentable where PlatformViewController == UIViewController {
    
    func makeUIViewController(context: Context) -> PlatformViewController {
        return makeViewController(context: context)
    }
    
    func updateUIViewController(_ uiViewController: PlatformViewController, context: Context) {
        return updateViewController(uiViewController, context: context)
    }
    
    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        dismantleViewController(uiViewController, coordinator: coordinator)
    }
}
#endif

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
//MARK: - AppKit forwarding
extension UnifiedPlatformRepresentable where PlatformViewController == NSViewController {
    
    func makeNSViewController(context: Context) -> PlatformViewController {
        return makeViewController(context: context)
    }
    
    func updateNSViewController(_ nsViewController: PlatformViewController, context: Context) {
        return updateViewController(nsViewController, context: context)
    }
    
    static func dismantleNSViewController(_ nsViewController: NSViewController, coordinator: Coordinator) {
        dismantleViewController(nsViewController, coordinator: coordinator)
    }
}
#endif
