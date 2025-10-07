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

    
//    @Query(sort: \IPTVChannel.sortHint, order: .forward)
//    private var channels: [IPTVChannel]
    
    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        return context.coordinator.guideController
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        //Not required - Updates handled via observation.
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
