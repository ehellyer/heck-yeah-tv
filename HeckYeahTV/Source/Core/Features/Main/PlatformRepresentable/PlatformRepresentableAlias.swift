//
//  PlatformRepresentableAlias.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

//MARK: - Cross platform aliases

#if canImport(AppKit) && !targetEnvironment(macCatalyst)

import AppKit

typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformView = NSView
typealias PlatformColor = NSColor

#elseif canImport(UIKit)

import UIKit

typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformView = UIView
typealias PlatformColor = UIColor

#endif

//MARK: - Platform Utilities

struct PlatformUtils {
    
    static func createView() -> PlatformView {
        let v = PlatformView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }
}

