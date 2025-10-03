//
//  GuideViewDelegate.swift
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
protocol GuideViewDelegate: AnyObject {
    
    func selectChannel(_ channel: IPTVChannel)
    
    func toggleFavoriteChannel(_ channel: IPTVChannel)
    
    func didBecomeFocused(target: FocusTarget)
}
