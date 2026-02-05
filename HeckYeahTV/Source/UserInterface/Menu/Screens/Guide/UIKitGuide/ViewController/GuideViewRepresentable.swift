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
    
    @FocusState.Binding var isFocused: Bool

    //MARK: - PlatformViewRepresentable overrides
    
    func makeViewController(context: Context) -> PlatformViewController {
        let controller = GuideViewController(nibName: nil, bundle: nil)
        return controller
    }
    
    func updateViewController(_ viewController: PlatformViewController, context: Context) {

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

