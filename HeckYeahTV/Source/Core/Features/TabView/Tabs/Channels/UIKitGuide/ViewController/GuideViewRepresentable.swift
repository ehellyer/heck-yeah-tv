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
    
    @Binding var appState: AppStateProvider
    @FocusState.Binding var isFocused: Bool    
    @Environment(ChannelMap.self) private var channelMap
    @Environment(\.modelContext) private var viewContext
    
    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        let controller = context.coordinator.guideController
        controller.appState = appState
        controller.channelMap = channelMap
        controller.viewContext = viewContext
        return controller
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        let controller = context.coordinator.guideController
        controller.appState = appState
        controller.channelMap = channelMap
        controller.viewContext = viewContext
    }
    
    static func dismantleViewController(_ viewController: PlatformViewController, coordinator: Coordinator) {
        coordinator.guideController.view.removeFromSuperview()
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    //MARK: - ViewControllerRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject {
        lazy var guideController: GuideViewController = GuideViewController()
    }
}
