//
//  GuideViewRepresentable.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

@MainActor
struct GuideViewRepresentable: UnifiedPlatformControllerRepresentable {
    
    //MARK: - Bound State
    
    @Environment(GuideStore.self) private var guideStore
    @FocusState.Binding var focus: FocusTarget?
    
    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        context.coordinator.guideControllerView.guideStore = guideStore
        return context.coordinator.guideControllerView
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        //Not required - Updates handled via observation.
    }
    
    static func dismantleViewController(_ viewController: PlatformViewController, coordinator: Coordinator) {
        coordinator.guideControllerView.delegate = nil
        coordinator.guideControllerView.view.removeFromSuperview()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    //MARK: - ViewControllerRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject, @MainActor GuideViewControllerDelegate  {
        lazy var guideControllerView: GuideViewController = {
            let vc = GuideViewController()
            vc.delegate = self
            return vc
        }()
        
        //MARK: - GuideViewControllerDelegate protocol
        func setFocus(_ target: FocusTarget) {
            //TODO: EJH - Fix this.
            //??? self.focus = target ???
        }
    }
}
