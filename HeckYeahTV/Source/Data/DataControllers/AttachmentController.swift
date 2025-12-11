//
//  AttachmentController.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/3/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI
import Hellfire

/// The AttachmentController: Because someone has to wrangle all these pixels from the internet.
///
/// This controller is your friendly neighborhood image fetcher. It goes out into the wild web,
/// finds your images, and brings them back home safely. Think of it as a golden retriever,
/// but for JPEGs and PNGs.
///
/// ## Overview
/// AttachmentController handles the exciting world of downloading images from URLs and
/// converting them into formats that SwiftUI and UIKit/AppKit actually understand.
/// It even caches things because downloading the same cat picture 47 times is inefficient
/// (and the cats judge you for it).
///

/// ## Fetching Images Like a Boss
/// - ``fetchImage(_:cachePolicyType:)``
/// - ``fetchPlatformImage(_:cachePolicyType:)``
class AttachmentController {
    
    deinit {
        logDebug("Deallocated")
    }
    
    //MARK: - Private API
    
    private lazy var sessionInterface = SessionInterface.sharedInstance
    
    //MARK: - Internal API
    
    /// Fetches an image and wraps it up in a fancy SwiftUI `Image` bow.
    ///
    /// This method does the heavy lifting of downloading your image and converting it into
    /// something SwiftUI can actually display. It's like a translator, but instead of languages,
    /// it translates "bytes from the internet" into "pretty pictures on screen."
    ///
    /// - Parameters:
    ///   - attachmentURL: The URL where your image lives. If it's `nil`, we return `nil` because
    ///     we're not magicians (yet). We can't fetch images from the void.
    ///   - cachePolicyType: How long to remember this image. Default is `.month` because we assume
    ///     your images don't go stale like milk. Unless they're food photos, in which case... 🤷‍♂️
    ///
    /// - Returns: A SwiftUI `Image` if everything went well, or `nil` if the internet failed you
    ///   (or you gave us a bad URL, but we won't point fingers).
    ///
    /// - Throws: Various networking errors, because the internet is a wild and unpredictable place.
    ///   Could be 404, could be no connection, could be Mercury in retrograde. Who knows?
    ///
    /// ## Example
    /// ```swift
    /// let controller = AttachmentController()
    /// let image = try await controller.fetchImage(someURL)
    /// // Look at that, you got yourself an image! 🎉
    /// ```
    func fetchImage(_ attachmentURL: URL?, cachePolicyType: CachePolicyType = .month) async throws -> Image? {
        
        guard let pfImage = try await fetchPlatformImage(attachmentURL, cachePolicyType: cachePolicyType) else {
            return nil
        }
        
#if canImport(UIKit)
        return Image(uiImage: pfImage)
#elseif canImport(AppKit)
        return Image(nsImage: pfImage)
#endif
    }
    
    /// Fetches an image in its raw platform-native form: `UIImage` or `NSImage`, depending on whether
    /// you're Team iOS or Team Mac.
    ///
    /// This is the "I need the actual platform image, not that SwiftUI wrapper stuff" method.
    /// Perfect for when you need to do some low-level pixel manipulation or you just really miss
    /// the old UIKit/AppKit days.
    ///
    /// - Parameters:
    ///   - attachmentURL: Where your image is hanging out on the internet. Pass `nil` if you
    ///     want to practice your error handling skills (we'll return `nil` right back at ya).
    ///   - cachePolicyType: How long we should hoard this image in our cache vault. Default is
    ///     `.month` which is basically forever in internet time.
    ///
    /// - Returns: A `PlatformImage` (secretly a `UIImage` or `NSImage`) if the download gods smile
    ///   upon you, or `nil` if things went sideways.
    ///
    /// - Throws: All sorts of networking shenanigans. Bad URL? Exception. No internet? Exception.
    ///   Server having a bad day? Believe it or not, also exception.
    ///
    /// ## Discussion
    /// This method speaks directly to your platform's native image type, so you can do all those
    /// fancy things that SwiftUI's `Image` doesn't let you do. Just remember: with great power
    /// comes great responsibility (and occasional memory leaks if you're not careful).
    func fetchPlatformImage(_ attachmentURL: URL?, cachePolicyType: CachePolicyType = .month) async throws -> PlatformImage? {
        
        guard let attachmentURL else {
            return nil
        }

        // Setup the request
        let request = NetworkRequest(url: attachmentURL,
                                     method: .get,
                                     cachePolicyType: cachePolicyType,
                                     timeoutInterval: 10.0,
                                     headers: [HTTPHeader(name: "accept-type", value: "image/png, image/jpeg, image/*;q=0.8, */*;q=0.2")])
        
        // Make the call
        let response = try await sessionInterface.execute(request)
        guard let data = response.body, let pfImage = PlatformImage(data: data) else {
            return nil
        }
        
        return pfImage
    }
}
