//
//  NSView+AsImage.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/5/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import AppKit

/// Extends `NSView` with convenient image rendering capabilities.
///
/// Because sometimes you need to turn your carefully crafted view hierarchy
/// into a flat image. It's like taking a photo of your LEGO creation
/// before your cat knocks it over.
extension NSView {
    
    /// Captures a snapshot of this view and its subviews as an `NSImage`, because screenshots are for quitters.
    ///
    /// This method uses `NSBitmapImageRep` (the macOS equivalent of iOS's renderer) to capture
    /// your view's entire layer hierarchy into a crispy image. Everything gets captured:
    /// subviews, shadows, rounded corners, that `CALayer` animation you spent 3 hours tweaking - all of it.
    ///
    /// The rendering happens synchronously on the calling thread, so maybe don't do this in a tight loop
    /// unless you enjoy watching your frame rate plummet like a stone.
    ///
    /// - Parameter opaque: Set to `true` if your view has no transparency and you want a performance boost.
    ///                     The renderer will skip alpha channel processing and your CPU will thank you.
    ///                     Defaults to `false` because we respect transparency around here.
    /// - Parameter scale: The scale factor for the resulting image. Pass `0.0` to automatically match
    ///                    the screen's native scale (recommended for Retina displays). Pass `1.0` for
    ///                    standard resolution, or `2.0` if you really want to flex those pixels.
    ///                    Defaults to `0.0`.
    ///
    /// - Returns: A shiny new `NSImage` containing your view's visual representation. 
    ///           No optionals here - this method is reliable like a Swiss watch, or at least like 
    ///           a Casio watch from the '90s that refuses to die.
    ///
    /// - Note: This method requires the view to be backed by a layer (`wantsLayer = true`).
    ///         If you haven't enabled layer-backing yet, what are you even doing? It's 2025.
    ///
    /// ## Example
    /// ```swift
    /// let fancyView = NSView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    /// fancyView.wantsLayer = true
    /// fancyView.layer?.backgroundColor = NSColor.systemBlue.cgColor
    /// fancyView.layer?.cornerRadius = 12
    /// 
    /// // Capture with transparency preserved - no optional unwrapping needed!
    /// let snapshot = fancyView.asImage()
    /// imageView.image = snapshot
    /// 
    /// // Capture with opaque rendering for better performance
    /// let opaqueSnapshot = fancyView.asImage(opaque: true)
    /// 
    /// // Create a high-res version at 2x scale
    /// let highRes = fancyView.asImage(scale: 2.0)
    /// ```
    func asImage(opaque: Bool = false, scale: CGFloat = 0.0) -> NSImage {
        self.layoutSubtreeIfNeeded()
        

        guard let bitmapRep = self.bitmapImageRepForCachingDisplay(in: self.bounds) else {
            return NSImage(size: bounds.size)
        }
        
        self.cacheDisplay(in: self.bounds, to: bitmapRep)
        
        guard let data = bitmapRep.representation(using: .png, properties: [:]),
              let image = NSImage(data: data) else {
            
            return NSImage(size: bounds.size)
        }
        
        return image
    }
}
