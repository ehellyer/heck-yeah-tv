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

    @Environment(\.modelContext) private var viewContext
    
    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        let controller = GuideViewController(nibName: nil, bundle: nil)
        controller.appState = appState
        controller.viewContext = viewContext
        return controller
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {
        let controller = viewController as? GuideViewController
        controller?.appState = appState
        controller?.viewContext = viewContext
    }
    
    static func dismantleViewController(_ viewController: PlatformViewController, coordinator: Coordinator) {
        
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    //MARK: - ViewControllerRepresentable Coordinator
    
    @MainActor
    final class Coordinator: NSObject { }
}

