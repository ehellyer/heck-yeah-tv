//
//  UIView+AsImage.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/4/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

/// Extends `UIView` with convenient image rendering capabilities.
///
/// Because sometimes you need to turn your carefully crafted view hierarchy
/// into a flat image. It's like taking a photo of your LEGO creation
/// before your cat knocks it over.
extension UIView {
    /// Captures a snapshot of this view and its subviews as a `UIImage`, because screenshots are for quitters.
    ///
    /// This method uses the modern `UIGraphicsImageRenderer` API (available since iOS 10, which was ages ago)
    /// to render your view's entire layer hierarchy into a crispy image. Everything gets captured:
    /// subviews, shadows, rounded corners, that `CALayer` animation you spent 3 hours tweaking - all of it.
    ///
    /// The rendering happens synchronously on the calling thread, so maybe don't do this in a tight loop
    /// unless you enjoy watching your frame rate plummet like a stone.
    ///
    /// - Parameter opaque: Set to `true` if your view has no transparency and you want a performance boost.
    ///                     The renderer will skip alpha channel processing and your CPU will thank you.
    ///                     Defaults to `false` because we respect transparency around here.
    /// - Parameter scale: The scale factor for the resulting image. Pass `0.0` to automatically match
    ///                    the device's native scale (recommended). Pass `1.0` for non-Retina peasant mode,
    ///                    or `3.0` if you really want to flex those pixels. Defaults to `0.0`.
    ///
    /// - Returns: A shiny new `UIImage` containing your view's visual representation. 
    ///           No optionals here - this method is reliable like a Swiss watch, or at least like 
    ///           a Casio watch from the '90s that refuses to die.
    ///
    /// - Note: This uses `UIGraphicsImageRenderer`, which handles wide color gamut automatically
    ///         and manages memory more efficiently than the legacy `UIGraphicsBeginImageContext` APIs.
    ///         You're welcome.
    ///
    /// ## Example
    /// ```swift
    /// let fancyView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    /// fancyView.backgroundColor = .systemBlue
    /// fancyView.layer.cornerRadius = 12
    /// 
    /// // Capture with transparency preserved - no optional unwrapping needed!
    /// let snapshot = fancyView.asImage()
    /// imageView.image = snapshot
    /// 
    /// // Capture with opaque rendering for better performance
    /// let opaqueSnapshot = fancyView.asImage(opaque: true)
    /// 
    /// // Create a thumbnail at 1x scale
    /// let thumbnail = fancyView.asImage(scale: 1.0)
    /// ```
    func asImage(opaque: Bool = false, scale: CGFloat = 0.0) -> UIImage {
        // Configure the rendering format with our desired settings
        let format = UIGraphicsImageRendererFormat()
        format.opaque = opaque
        format.scale = scale
        
        // Create the renderer and let it work its magic
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: format)
        return renderer.image { context in
            // Render the entire layer tree into the graphics context
            layer.render(in: context.cgContext)
        }
    }
}

