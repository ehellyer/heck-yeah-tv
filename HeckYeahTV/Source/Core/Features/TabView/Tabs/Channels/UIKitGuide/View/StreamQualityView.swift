//
//  StreamQualityView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

/// Extension that adds image generation capabilities to `StreamQuality` enum values.
///
/// Because sometimes you need a pretty badge to show off your 4K UHD glory,
/// and sometimes you're stuck with "SD" (hey, at least it's honest).
@MainActor
extension StreamQuality {

    /// Returns a template-mode image for this stream quality, because who wants to render the same badge 47 times?
    ///
    /// This computed property implements a lazy caching strategy that would make your CS professor proud:
    /// - First attempt: Check the cache like a responsible developer
    /// - Cache miss: Sigh heavily, create a fresh `StreamQualityView`, render it to an image, and stash it for next time
    /// - Unknown quality: Returns `nil` faster than you can say "404"
    ///
    /// The resulting image uses `.alwaysTemplate` rendering mode, so you can tint it to your heart's content
    /// without creating a million variations. You're welcome.
    ///
    /// - Returns: A cached `PlatformImage` ready for your UI, or `nil` if the quality is unknown
    ///           (or if the universe decides to throw a tantrum and image rendering fails).
    var image: PlatformImage? {
        let streamQuality = self
        guard streamQuality != .unknown else {
            return nil
        }
        var image = Self.cachedImages[streamQuality]
        // If cache-miss, create a new image and cache it.
        if image == nil {
            let view = StreamQualityView(streamQuality: self)
            
            // Force layout so Auto Layout does its thing and gives us proper bounds
            view.layoutIfNeeded()
            image = view.asImage().withRenderingMode(.alwaysTemplate)
            Self.cachedImages[streamQuality] = image
        }
        return image
    }
    
    /// The sacred cache where we store our precious rendered images.
    ///
    /// Built once, reused forever (or until the app terminates). This is peak efficiency, folks.
    private static var cachedImages: [StreamQuality: PlatformImage] = [:]
}

/// A view that renders a stream quality badge with rounded corners and a border.
///
/// This isn't your grandma's `UILabel` - it's a fancy label *with style*.
/// Think of it as putting lipstick on a pig, except the pig is actually pretty cute
/// and the lipstick is Auto Layout constraints.
///
/// The view creates a white-bordered, rounded rectangle badge that displays
/// quality text like "HD", "FHD", "4K", etc. Perfect for when you want to
/// flex about your streaming resolution.
@MainActor
class StreamQualityView: PlatformView {
    
    // MARK: - Initialization
    
    /// Creates a new stream quality badge view.
    ///
    /// Constructs a view that renders the given quality as a styled badge.
    /// The initial frame size is irrelevant since Auto Layout will resize it
    /// based on the label's intrinsic content size (as the prophecy foretold).
    ///
    /// - Parameter streamQuality: The quality level to display. Choose wisely.
    init(streamQuality: StreamQuality) {
        super.init(frame: CGRect(x: 0, y: 0, width: 300, height: 240))  // Arbitrary size, Auto Layout will fix our mistakes
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = false
        
        self.commonInit(streamQuality)
    }
    
    /// Storyboard initialization - not supported because we have standards.
    ///
    /// If you somehow manage to call this, the app will crash spectacularly
    /// with a `logFatal` message. Consider this a feature, not a bug.
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    // MARK: - Private Setup
    
    /// Sets up the view's appearance and layout constraints.
    ///
    /// Creates a label with the quality text, wraps it in a rounded rectangle border,
    /// and configures Auto Layout so everything sizes itself properly. It's like magic,
    /// but with more code and slightly less disappointment.
    ///
    /// Platform-specific styling:
    /// - **macOS**: Uses layer-backed rendering (because `NSView` is fancy)
    /// - **iOS/tvOS**: Direct layer access (because `UIView` is straightforward)
    ///
    /// - Parameter streamQuality: The quality to display in the badge.
    private func commonInit(_ streamQuality: StreamQuality) {
        
        tag = Self.viewTypeTagId
        
        // Create the label that will show our quality text
        let label = PlatformUtils.createLabel()
        label.font = AppStyle.Fonts.streamQualityFont
        label.textColor = .white
        label.textValue = streamQuality.name
        
        // Set up Auto Layout constraints - padding of 5pt horizontal, 3pt vertical
        // because we're not animals who put text right up against the border
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
        self.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: 3).isActive = true
        self.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 3).isActive = true
        
        // Tell Auto Layout: "You WILL respect the label's size, no negotiation"
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Style the container with rounded corners and a border
        // Same visual result on all platforms, different APIs because... reasons
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = PlatformColor.white.cgColor
        layer.masksToBounds = false
        self.backgroundColor = PlatformColor.clear
    }
    
    // MARK: - Constants
    
    /// A unique identifier for this view type.
    ///
    /// This absurdly large number was chosen by keyboard-mashing,
    /// quantum randomness, or possibly divine intervention.
    /// Either way, it's unique enough to avoid collisions with other view tags.
    static let viewTypeTagId: Int = 23456604455
}
