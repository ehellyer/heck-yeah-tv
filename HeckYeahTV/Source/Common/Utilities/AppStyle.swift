//
//  AppStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/5/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct AppStyle {
    
    static var cornerRadius: CGFloat {
        return 20
    }
    
    struct ProgramView {
#if os(tvOS)
        static var width: CGFloat = 320
#else
        static var width: CGFloat = 260
#endif
    }
    
    struct Fonts {
        
        static var gridRowFont: Font {
#if os(tvOS)
            .subheadline
#else
            .body
#endif
            
        }
        
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
        

        static var programTimeSlotFont: PlatformFont {
#if os(tvOS)
            .systemFont(ofSize: 23, weight: .bold)
#elseif os(iOS)
            .systemFont(ofSize: 17, weight: .bold)
#else
            .systemFont(ofSize: 17, weight: .bold)
#endif
        }
        
        static var programTitleFont: PlatformFont {
#if os(tvOS)
            .systemFont(ofSize: 23, weight: .regular)
#elseif os(iOS)
            .systemFont(ofSize: 17, weight: .regular)
#else
            .systemFont(ofSize: 17, weight: .regular)
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
