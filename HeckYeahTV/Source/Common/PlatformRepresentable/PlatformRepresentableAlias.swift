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
typealias PlatformViewController = NSViewController
typealias PlatformColor = NSColor
typealias PlatformLabel = NSTextField
typealias PlatformFont = NSFont
typealias PlatformStackView = NSStackView
typealias PlatformImageView = NSImageView
typealias PlatformImage = NSImage
typealias PlatformPressGestureRecognizer = NSPressGestureRecognizer
typealias PlatformConstraintAxis = NSLayoutConstraint.Orientation
typealias PlatformTableView = NSTableView
typealias PlatformTableViewCell = NSTableCellView
typealias PlatformScrollView = NSScrollView

#elseif canImport(UIKit)

import UIKit

typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformView = UIView
typealias PlatformViewController = UIViewController
typealias PlatformColor = UIColor
typealias PlatformLabel = UILabel
typealias PlatformFont = UIFont
typealias PlatformStackView = UIStackView
typealias PlatformImageView = UIImageView
typealias PlatformImage = UIImage
typealias PlatformPressGestureRecognizer = UILongPressGestureRecognizer
typealias PlatformConstraintAxis = NSLayoutConstraint.Axis
typealias PlatformTableView = UITableView
typealias PlatformTableViewCell = UITableViewCell
typealias PlatformScrollView = UIScrollView

#endif


//MARK: - Subclassed Platform Types (UIKit/AppKit shims)

class CrossPlatformLabel: PlatformLabel {
    var textValue: String? {
        get {
#if canImport(UIKit)
            return self.text
#elseif canImport(AppKit)
            return self.stringValue
#endif
        }
        set {
#if canImport(UIKit)
            self.text = newValue
#elseif canImport(AppKit)
            self.stringValue = newValue ?? ""
#endif
        }
    }
    
    var lineLimit: Int {
        get {
#if canImport(UIKit)
            return self.numberOfLines
#elseif canImport(AppKit)
            return self.maximumNumberOfLines
#endif
        }
        set {
#if canImport(UIKit)
            self.numberOfLines = newValue
#elseif canImport(AppKit)
            self.maximumNumberOfLines = newValue
#endif
        }
    }
}

class CrossPlatformView: PlatformView {
    
    var bgColor: PlatformColor? {
        get {
#if os(macOS)
            guard let cg = self.layer?.backgroundColor else { return nil }
            return PlatformColor(cgColor: cg)
#else
            return self.backgroundColor
#endif
        }
        set {
#if os(macOS)
            if self.wantsLayer == false { self.wantsLayer = true }
            self.layer?.backgroundColor = newValue?.cgColor
#else
            self.backgroundColor = newValue
#endif
        }
    }
    
}

//MARK: - Platform Extensions

#if os(macOS)

/// UIScrollView.contentInset compatibility
struct NSEdgeInsetsCompat {
    var top: CGFloat
    var left: CGFloat
    var bottom: CGFloat
    var right: CGFloat
    static let zero = NSEdgeInsetsCompat(top: 0, left: 0, bottom: 0, right: 0)
}

private var contentInsetKey: UInt8 = 0

extension NSScrollView {
    var contentInset: NSEdgeInsetsCompat {
        get {
            (objc_getAssociatedObject(self, &contentInsetKey) as? NSEdgeInsetsCompat) ?? .zero
        }
        set {
            objc_setAssociatedObject(self, &contentInsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            // Implement a simple padding by adjusting the documentView’s frame inset within the clipView’s bounds.
            guard let doc = self.documentView else { return }
            var frame = self.contentView.bounds
            frame.origin.x += newValue.left
            frame.size.width -= (newValue.left + newValue.right)
            frame.origin.y += newValue.top
            frame.size.height -= (newValue.top + newValue.bottom)
            doc.frame = frame
        }
    }
}
#endif

//MARK: - Platform Utilities

struct PlatformUtils {
    
    // Create View
    
    static func createView() -> CrossPlatformView {
        let view: CrossPlatformView = CrossPlatformView()
#if !os(macOS)
        view.backgroundColor = PlatformColor.clear
#endif
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    // Create Label
    
    static func createLabel(text: String = "", font: PlatformFont? = nil) -> CrossPlatformLabel {
        let label = CrossPlatformLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textValue = text
        if let font {
            label.font = font
        }
#if os(macOS)
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = PlatformColor.clear
#endif
        return label
    }
    
    // Create ImageView
    
    static func createImageView() -> PlatformImageView {
        let imageView = PlatformImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    // Create StackView
        
    static func createStackView(axis: PlatformConstraintAxis) -> PlatformStackView {
        let stackView = PlatformStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
#if os(macOS)
        stackView.orientation = axis == .horizontal ? .horizontal : .vertical
        stackView.spacing = 8
#else
        stackView.axis = axis
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.alignment = .center
#endif
        return stackView
    }

    // Create ScrollView
    
    static func createScrollView() -> PlatformScrollView {
        let scrollView = PlatformScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
#if os(macOS)
        scrollView.hasHorizontalScroller = true
        scrollView.hasVerticalScroller = false
        scrollView.autohidesScrollers = true
#else
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
#endif
        return scrollView
    }
    
    // Create TableView
    
    static func createTableView() -> PlatformTableView {
        let tableView = PlatformTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
}

