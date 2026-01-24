//
//  AKPageControl.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/13/26.
//

import AppKit

class AKPageControl: NSView {
    
    //MARK: - NSView Overrides
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    override var intrinsicContentSize: NSSize {
        let visibleCount = min(numberOfPages, maxVisibleDots)
        let width = CGFloat(visibleCount) * dotSize + CGFloat(max(0, visibleCount - 1)) * (dotSpacing - dotSize)
        let hozPadding: CGFloat = 20
        let verPadding: CGFloat = 8
        return NSSize(width: width + hozPadding, height: dotSize + verPadding)
    }
    
    override func layout() {
        super.layout()
        updateDotLayers()
    }
    
    override func mouseDragged(with event: NSEvent) {
        let deltaX = event.deltaX
        
        // Rate limit updates per second
        let now = Date()
        if let lastUpdate = lastDragUpdate {
            let timeSinceLastUpdate = now.timeIntervalSince(lastUpdate)
            if timeSinceLastUpdate < dragUpdateInterval {
                return
            }
        }
        
        lastDragUpdate = now
        updatePageUsing(deltaX: deltaX)
    }
    
    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        
        let visibleCount = visibleRange.count
        let totalWidth = CGFloat(visibleCount) * dotSize + CGFloat(visibleCount - 1) * (dotSpacing - dotSize)
        let startX = (bounds.width - totalWidth) / 2
        let centerY = bounds.height / 2
        
        for (index, page) in visibleRange.enumerated() {
            let x = startX + CGFloat(index) * dotSpacing
            let scale = self.scale(for: page)
            let scaledDotSize = dotSize * scale
            
            // Create hit area for the dot (expanded for easier clicking)
            let hitAreaPadding: CGFloat = 4
            let hitRect = CGRect(
                x: x - hitAreaPadding,
                y: centerY - scaledDotSize / 2 - hitAreaPadding,
                width: scaledDotSize + (hitAreaPadding * 2),
                height: scaledDotSize + (hitAreaPadding * 2)
            )
            
            if hitRect.contains(location) {
                currentPage = page
                onPageChange?(currentPage)
                return
            }
        }
    }
    
    //MARK: - Private API

    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 12
    private let maxVisibleDots: Int = 9 // Maximum number of dots to show at once
    private let edgeScaleFactor: CGFloat = 0.5 // Scale factor for edge dots
    private var visibleRange: Range<Int> = 0..<0
    private var previousVisibleRange: Range<Int> = 0..<0
    private var dotLayers: [CAShapeLayer] = []
    private var lastDragUpdate: Date?
    private let dragUpdateInterval: TimeInterval = 0.1
    private enum PageDirection {
        case forward
        case backward
    }
    
    private func setupLayers() {
        wantsLayer = true
        
        guard let layer = self.layer else { return }
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        dotLayers.removeAll()
    }
    
    private func updateDotLayers() {
        guard numberOfPages > 0 else { return }
        guard let containerLayer = self.layer else { return }
        
        let visibleCount = visibleRange.count
        
        // Store page numbers for existing layers
        var existingPages: [Int: CAShapeLayer] = [:]
        for (index, layer) in dotLayers.enumerated() {
            if index < previousVisibleRange.count {
                let page = previousVisibleRange.lowerBound + index
                existingPages[page] = layer
            }
        }
        
        // Build new layer array matching new visible range
        var newLayers: [CAShapeLayer] = []
        for page in visibleRange {
            if let existingLayer = existingPages[page] {
                // Reuse existing layer
                newLayers.append(existingLayer)
                existingPages.removeValue(forKey: page)
            } else {
                // Create new layer for pages that just became visible
                let dotLayer = CAShapeLayer()
                containerLayer.addSublayer(dotLayer)
                newLayers.append(dotLayer)
            }
        }
        
        // Remove layers that are no longer visible
        for (_, layer) in existingPages {
            layer.removeFromSuperlayer()
        }
        
        dotLayers = newLayers
        previousVisibleRange = visibleRange
        
        let totalWidth = CGFloat(visibleCount) * dotSize + CGFloat(visibleCount - 1) * (dotSpacing - dotSize)
        let startX = (bounds.width - totalWidth) / 2
        let centerY = bounds.height / 2
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
        
        for (index, page) in visibleRange.enumerated() {
            let dotLayer = dotLayers[index]
            let x = startX + CGFloat(index) * dotSpacing
            let scale = self.scale(for: page)
            
            // Create path with standard size
            let rect = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
            let path = CGPath(ellipseIn: rect, transform: nil)
            
            // Set path if not already set
            if dotLayer.path == nil {
                dotLayer.path = path
            }
            
            // Animate position and scale
            dotLayer.position = CGPoint(x: x + dotSize / 2, y: centerY)
            dotLayer.bounds = CGRect(x: 0, y: 0, width: dotSize, height: dotSize)
            dotLayer.transform = CATransform3DMakeScale(scale, scale, 1.0)
            
            // Animate color
            if page == currentPage {
                dotLayer.fillColor = NSColor.controlAccentColor.cgColor
            } else {
                dotLayer.fillColor = NSColor.placeholderTextColor.cgColor
            }
        }
        
        CATransaction.commit()
    }

    private func updatePageUsing(deltaX: CGFloat) {
        guard abs(deltaX) != 0 else { return }
        if deltaX < 0 && currentPage > 0 {
            updateCurrentPageUsing(direction: .backward)
        } else if deltaX > 0 && currentPage < numberOfPages - 1 {
            updateCurrentPageUsing(direction: .forward)
        }
    }
    
    private func updateCurrentPageUsing(direction: AKPageControl.PageDirection) {
        switch direction {
            case .backward:
                currentPage -= 1
            case .forward:
                currentPage += 1
        }
        onPageChange?(currentPage)
        updateDotLayers()
    }
    
    private func updateVisibleRange() {
        guard numberOfPages > 0 else {
            visibleRange = 0..<0
            return
        }
        
        guard numberOfPages > maxVisibleDots else {
            visibleRange = 0..<numberOfPages
            return
        }
        
        // Calculate the range centered around the current page
        let halfVisible = maxVisibleDots / 2
        var start = currentPage - halfVisible
        var end = currentPage + halfVisible + 1
        
        // Adjust if we're near the beginning
        if start < 0 {
            end += abs(start)
            start = 0
        }
        
        // Adjust if we're near the end
        if end > numberOfPages {
            start -= (end - numberOfPages)
            end = numberOfPages
        }
        
        // Ensure we don't go below 0
        start = max(0, start)
        
        visibleRange = start..<end
    }
    
    private func scale(for page: Int) -> CGFloat {
        // If all pages are visible, no scaling needed
        if numberOfPages <= maxVisibleDots {
            return 1.0
        }
        
        // Check if we're at the start edge
        if page == visibleRange.lowerBound && visibleRange.lowerBound > 0 {
            return edgeScaleFactor
        }
        
        // Check if we're at the end edge
        if page == visibleRange.upperBound - 1 && visibleRange.upperBound < numberOfPages {
            return edgeScaleFactor
        }
        
        return 1.0
    }
    
    //MARK: - Internal API
    
    var numberOfPages: Int = 0 {
        didSet {
            updateVisibleRange()
            updateDotLayers()
        }
    }
    
    var currentPage: Int = 0 {
        didSet {
            updateVisibleRange()
            updateDotLayers()
        }
    }
    
    var onPageChange: ((Int) -> Void)?
}
