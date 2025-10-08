//
//  GuideViewRepresentable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import SwiftData

@MainActor
struct GuideViewRepresentable: UnifiedPlatformControllerRepresentable {
    
    //MARK: - Bound State
    @FocusState.Binding var focus: FocusTarget?
    @Binding var appState: SharedAppState

    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        // Inject the current appState into the controller.
        context.coordinator.guideController.appState = appState
        return context.coordinator.guideController
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        // Keep the controller's appState in sync as the binding changes.
        context.coordinator.guideController.appState = appState
        // Other updates are handled via observation that we’ll add in the controller.
    }
    
    static func dismantleViewController(_ viewController: PlatformViewController, coordinator: Coordinator) {
        coordinator.guideController.delegate = nil
        coordinator.guideController.view.removeFromSuperview()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    //MARK: - ViewControllerRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {
        
        lazy var guideController: GuideViewController = {
            let vc = GuideViewController()
            vc.delegate = self
            return vc
        }()
    }
}

extension GuideViewRepresentable.Coordinator: @MainActor GuideViewControllerDelegate {
    
    //MARK: - GuideViewControllerDelegate protocol
    func setFocus(_ target: FocusTarget) {
        //TODO: EJH - Fix this.
        //??? self.focus = target ???
    }
}
