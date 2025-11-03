//
//  GuideViewRepresentable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

@MainActor
struct GuideViewRepresentable: CrossPlatformControllerRepresentable {
    
    //MARK: - Bound State
    
    @Binding var appState: SharedAppState
    @FocusState.Binding var focusTarget: FocusTarget?
    @Environment(ChannelMap.self) private var channelMap
    
    // Track if we should request initial focus
    var shouldRequestInitialFocus: Bool = false
    
    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        let controller = context.coordinator.guideController
        controller.appState = appState
        controller.channelMap = channelMap
        return controller
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        guard let controller = viewController as? GuideViewController else { return }
        
        controller.appState = appState
        controller.channelMap = channelMap
        
        // Handle focus updates triggered from SwiftUI to UIKit
        if let focusTarget = focusTarget, focusTarget != context.coordinator.lastProcessedFocus {
            context.coordinator.lastProcessedFocus = focusTarget
            
            // When SwiftUI sets a guide focus target, we need to apply it in UIKit
            if case .guide(let channelId, let col) = focusTarget {
                // First, make sure the view controller can receive focus
                controller.setNeedsFocusUpdate()
                controller.updateFocusIfNeeded()
                
                // Then apply the specific focus
                context.coordinator.applyFocusToGuide(channelId: channelId, col: col)
            }
        }
    }
    
    static func dismantleViewController(_ viewController: PlatformViewController, coordinator: Coordinator) {
        coordinator.guideController.view.removeFromSuperview()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    //MARK: - ViewControllerRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {
        var parent: GuideViewRepresentable
        var lastProcessedFocus: FocusTarget?
        
        init(parent: GuideViewRepresentable) {
            self.parent = parent
        }
        
        lazy var guideController: GuideViewController = {
            let vc = GuideViewController()
            return vc
        }()
        
        func applyFocusToGuide(channelId: String, col: Int) {

            // Make sure the cell is visible
            #if !os(macOS)
            guideController.scrollToSelectedChannelAndFocus()
            #endif
        }
    }
}
