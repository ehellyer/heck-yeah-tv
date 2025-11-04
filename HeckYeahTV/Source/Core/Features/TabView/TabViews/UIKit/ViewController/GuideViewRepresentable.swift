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
    }
}
