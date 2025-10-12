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
struct GuideViewRepresentable: CrossPlatformControllerRepresentable {
    
    //MARK: - Bound State
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
        
#if os(tvOS)
        // If SwiftUI binding changed, you could optionally push focus into UIKit here.
//        if let target = focus {
//            context.coordinator.guideController.setFocus(target)
//        }
#endif
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

//MARK: - GuideViewControllerDelegate protocol
extension GuideViewRepresentable.Coordinator: @MainActor GuideViewControllerDelegate {

    func setFocus(_ target: FocusTarget) {
//        self.guideController.appState.legacyKitFocus = target
    }
}
