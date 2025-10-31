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
    @Environment(ChannelMap.self) private var channelMap
    
    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        context.coordinator.guideController.appState = appState
        context.coordinator.guideController.channelMap = channelMap
        return context.coordinator.guideController
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        context.coordinator.guideController.appState = appState
        context.coordinator.guideController.channelMap = channelMap
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
