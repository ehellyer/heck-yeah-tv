//
//  AppStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/5/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct AppStyle {
    struct Fonts {
        static var titleFont: PlatformFont {
#if os(tvOS)
            .systemFont(ofSize: 28, weight: .semibold)
#elseif os(iOS)
            .systemFont(ofSize: 17, weight: .semibold)
#else
            .systemFont(ofSize: 17, weight: .semibold)
#endif
        }
        
        static var subtitleFont: PlatformFont {
#if os(tvOS)
            .systemFont(ofSize: 24)
#elseif os(iOS)
            .systemFont(ofSize: 13)
#else
            .systemFont(ofSize: 13)
#endif
        }
        
            
        static var programTitleFont: PlatformFont {
#if os(tvOS)
            .systemFont(ofSize: 23, weight: .medium)
#elseif os(iOS)
            .systemFont(ofSize: 17, weight: .medium)
#else
            .systemFont(ofSize: 17, weight: .medium)
#endif
        }
        
        static var programTimeFont: PlatformFont {
#if os(tvOS)
            .systemFont(ofSize: 24, weight: .semibold)
#elseif os(iOS)
            .systemFont(ofSize: 18, weight: .medium)
#else
            .systemFont(ofSize: 18, weight: .medium)
#endif
        }
        
        static var streamQualityFont: PlatformFont {
#if os(tvOS)
            .systemFont(ofSize: 15, weight: .regular)
#elseif os(iOS)
            .systemFont(ofSize: 8, weight: .regular)
#else
            .systemFont(ofSize: 8, weight: .regular)
#endif
        }
    }
}
