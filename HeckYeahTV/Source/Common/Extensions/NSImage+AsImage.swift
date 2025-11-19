//
//  NSImage+AsImage.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import AppKit
import SwiftUI

extension NSImage {
    var asImage: Image { return Image(nsImage: self) }
}
