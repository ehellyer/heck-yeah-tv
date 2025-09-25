//
//  GuideFocusViewDelegate.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/24/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
protocol GuideFocusViewDelegate: AnyObject {
    
    func selectChannel(_ channel: GuideChannel)
    
    func toggleFavoriteChannel(_ channel: GuideChannel)
    
    func didBecomeFocused(target: FocusTarget)
    
    func didLoseFocus(target: FocusTarget)
}
