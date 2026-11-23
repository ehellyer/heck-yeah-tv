//
//  PlatformRepresentableAlias.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/15/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

//MARK: - Cross platform aliases

#if canImport(UIKit)
import UIKit

typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformView = UIView
typealias PlatformViewController = UIViewController
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
typealias PlatformLabel = UILabel
#elseif canImport(AppKit)
import AppKit

typealias PlatformViewControllerRepresentable = NSViewControllerRepresentable
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformView = NSView
typealias PlatformViewController = NSViewController
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
typealias PlatformLabel = NSTextField
#endif

