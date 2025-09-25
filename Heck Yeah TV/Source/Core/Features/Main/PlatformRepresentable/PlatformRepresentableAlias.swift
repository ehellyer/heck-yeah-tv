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
typealias PlatformStackView = NSStackView

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
typealias PlatformStackView = UIStackView

#endif

//MARK: - Platform Utilities

struct PlatformUtils {
    
    static func createLabel(text: String = "", font: PlatformFont? = nil) -> PlatformLabel {
        let label = PlatformLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
#if os(macOS)
        label.stringValue = text
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        if let font = font {
            label.font = font
        }
#else
        label.text = text
        if let font = font {
            label.font = font
        }
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
    
    static func createStackView(axis: NSLayoutConstraint.Axis) -> PlatformStackView {
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
    
    static func createView() -> PlatformView {
        let view = PlatformView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }
    
    static func createTableView() -> PlatformTableView {
        let tableView = PlatformTableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }
}
