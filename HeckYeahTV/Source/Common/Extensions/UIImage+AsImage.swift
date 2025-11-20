//
//  UIImage+AsImage.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit
import SwiftUI

extension UIImage {
    var asImage: Image {
        return Image(uiImage: self)
    }
}
