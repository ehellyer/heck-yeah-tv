//
//  NSImage+AsImage.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

#if canImport(AppKit) //&& !targetEnvironment(macCatalyst)

import AppKit

extension PlatformImage {
    /// Converts APKit NSImage into SwiftUI Image
    var asImage: Image {
        return Image(nsImage: self)
    }
}

#elseif canImport(UIKit)

import UIKit

extension PlatformImage {
    /// Converts UIKit UIImage into SwiftUI Image
    var asImage: Image {
        return Image(uiImage: self)
    }
}

#endif





