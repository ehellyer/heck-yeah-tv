//
//  HorizontalClipContainer.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/23/25.
//  Copyright © 2025 Hellyer Multimedia.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Soft-clips (fades out) content on the left/right edges.
/// `leftClip` / `rightClip` are fade widths (pts) from opaque → transparent.
final class HorizontalClipContainer: PlatformView {
    
    //MARK: - PlatformView Overrides
    
//    deinit {
//        logDebug("Deallocated")
//    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = false
#if os(macOS)
        wantsLayer = true
        layer?.masksToBounds = false
#else
        layer.masksToBounds = false
#endif
        
        // Gradient used as alpha mask: [clear, opaque, opaque, clear]
        gradientMask.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMask.endPoint = CGPoint(x: 1, y: 0.5)
        gradientMask.colors = [
            PlatformColor.black.withAlphaComponent(0).cgColor,
            PlatformColor.black.cgColor,
            PlatformColor.black.cgColor,
            PlatformColor.black.withAlphaComponent(0).cgColor
        ]
        
        // Apply the gradient as an alpha mask
#if os(macOS)
        layer?.mask = gradientMask
#else
        layer.mask = gradientMask
#endif
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
#if os(macOS)
    override func layout() {
        super.layout()
        applyMaskLayout()
    }
#else
    override func layoutSubviews() {
        super.layoutSubviews()
        applyMaskLayout()
    }
#endif
    
    //MARK: - Private
    
    private let gradientMask = CAGradientLayer()
    
    private func applyMaskLayout() {
        guard bounds.width > 0 else { return }
        
        // Make the mask very tall so vertical overflow (shadows/halos) remains visible.
        let extra: CGFloat = 10_000
        let maskFrame = bounds.insetBy(dx: 0, dy: -extra * 0.5)
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        gradientMask.frame = maskFrame
        
        // Normalize fade widths to 0...1 across the container width.
        let w = bounds.width
        let left  = max(0, min(leftClip,  w)) / w           // 0..1
        let right = max(0, min(rightClip, w)) / w           // 0..1
        
        // Opaque band is [left .. (1 - right)]
        let leftEnd     = left                   // end of left fade (fully opaque begins)
        let rightStart  = 1 - right             // start of right fade (fully opaque ends)
        
        gradientMask.locations = [
            NSNumber(value: 0.0),
            NSNumber(value: Double(leftEnd)),
            NSNumber(value: Double(rightStart)),
            NSNumber(value: 1.0)
        ]
        
        CATransaction.commit()
    }
    
    //MARK: - Internal API
    
    /// Fade width from the left edge (points). 0 = no left fade.
    var leftClip: CGFloat  = 40 {
        didSet {
#if os(macOS)
            needsLayout = true
#else
            setNeedsLayout()
#endif
        }
    }
    
    /// Fade width from the right edge (points). 0 = no right fade.
    var rightClip: CGFloat = 40 {
        didSet {
#if os(macOS)
            needsLayout = true
#else
            setNeedsLayout()
#endif
        }
    }
}
