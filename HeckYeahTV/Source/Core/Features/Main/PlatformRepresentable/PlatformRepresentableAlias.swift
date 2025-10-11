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
//typealias PlatformViewControllerType = NSViewControllerType
typealias PlatformViewRepresentable = NSViewRepresentable
typealias PlatformView = NSView
typealias PlatformViewController = NSViewController
typealias PlatformCollectionView = NSCollectionView
typealias PlatformCollectionViewCell = NSCollectionViewItem
typealias PlatformTableView = NSTableView
typealias PlatformTableViewCell = NSTableCellView
typealias PlatformScrollView = NSScrollView
typealias PlatformImageView = NSImageView
typealias PlatformColor = NSColor
typealias PlatformFont = NSFont
typealias PlatformImage = NSImage
typealias PlatformButton = NSButton
typealias PlatformLabel = NSTextField
typealias PlatformTextField = NSTextField
typealias PlatformStackView = NSStackView
typealias PlatformConstraintAxis = NSLayoutConstraint.Orientation
typealias PlatformPressGestureRecognizer = NSPressGestureRecognizer

#elseif canImport(UIKit)

import UIKit

typealias PlatformViewControllerRepresentable = UIViewControllerRepresentable
//typealias PlatformViewControllerType = UIViewControllerType
typealias PlatformViewRepresentable = UIViewRepresentable
typealias PlatformView = UIView
typealias PlatformViewController = UIViewController
typealias PlatformCollectionView = UICollectionView
typealias PlatformCollectionViewCell = UICollectionViewCell
typealias PlatformTableView = UITableView
typealias PlatformTableViewCell = UITableViewCell
typealias PlatformScrollView = UIScrollView
typealias PlatformImageView = UIImageView
typealias PlatformColor = UIColor
typealias PlatformFont = UIFont
typealias PlatformImage = UIImage
typealias PlatformButton = UIButton
typealias PlatformLabel = UILabel
typealias PlatformTextField = UITextField
typealias PlatformStackView = UIStackView
typealias PlatformConstraintAxis = NSLayoutConstraint.Axis
typealias PlatformPressGestureRecognizer = UILongPressGestureRecognizer

#endif

//MARK: - Platform Utilities

#if canImport(UIKit)
@available(tvOS 13.0, *)
private final class NonFocusableView_tvOS: UIView {
    override var canBecomeFocused: Bool { false }
}
#endif


class CrossPlatformTextField: PlatformTextField {
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
}

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

//MARK: - UIKit/AppKit shims

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

#if os(macOS)
extension NSView {

    
    var isUserInteractionEnabled: Bool {
        get { return true } // NSView always accepts events unless disabled via other means
        set { /* no-op to mirror UIKit API */ }
    }
}

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

struct PlatformUtils {
    
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
    
    static func createButton(title: String = "") -> PlatformButton {
        let button = PlatformButton()
        button.translatesAutoresizingMaskIntoConstraints = false
#if os(macOS)
        button.title = title
        button.isBordered = false
#else
        button.setTitle(title, for: .normal)
#endif
        return button
    }
    
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
    
    static func createImageView() -> PlatformImageView {
        let imageView = PlatformImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }
    
    static func createView() -> CrossPlatformView {
        let view: CrossPlatformView = CrossPlatformView()
#if !os(macOS)
        view.backgroundColor = PlatformColor.clear
#endif
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    static func createTableView() -> PlatformTableView {
        let tableView = PlatformTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
}

