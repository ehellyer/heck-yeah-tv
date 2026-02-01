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
    
#if os(tvOS)
    static let rowHeight : CGFloat = 150
#else
    static let rowHeight : CGFloat = 80
#endif
    
    
    struct BootSplashScreen {
#if os(tvOS)
        static let titleFontSize: CGFloat =  120
        static let subtitleFontSize: CGFloat =  50
        static let imageFrame: CGFloat = 200
#elseif os(iOS)
        static let titleFontSize: CGFloat =  UIDevice.current.userInterfaceIdiom == .pad ? 80 : 50
        static let subtitleFontSize: CGFloat =  UIDevice.current.userInterfaceIdiom == .pad ? 40 : 24
        static let imageFrame: CGFloat = 100
#elseif os(macOS)
        static let titleFontSize: CGFloat =  80
        static let subtitleFontSize: CGFloat =  32
        static let imageFrame: CGFloat = 100
#else
        static let titleFontSize: CGFloat =  90
        static let subtitleFontSize: CGFloat =  40
        static let imageFrame: CGFloat = 100
#endif
        
    }
    
    struct FavoritesView {
#if os(tvOS)
        static let width: CGFloat = 120
        static let scaleEffect: CGFloat = 1.2
        static let height : CGFloat = AppStyle.rowHeight
        static let internalHorizontalPadding: CGFloat = 15
        static let internalVerticalPadding: CGFloat = 15
#else
        static let width: CGFloat = 70
        static let scaleEffect: CGFloat = 1.5
        static let height : CGFloat = AppStyle.rowHeight
        static let internalHorizontalPadding: CGFloat = 15
        static let internalVerticalPadding: CGFloat = 15
#endif
    }
    
    
    struct ChannelView {
#if os(tvOS)
        static let minWidth: CGFloat = 420
        static let height: CGFloat = AppStyle.rowHeight
        static let logoFrame: CGFloat = 70
        static let internalHorizontalPadding: CGFloat = 15
        static let internalVerticalPadding: CGFloat = 15
        static let favButtonTrailing: CGFloat = 25
#else
        static let minWidth: CGFloat = 300
        static let height : CGFloat = AppStyle.rowHeight
        static let logoFrame: CGFloat = 60
        static let internalHorizontalPadding: CGFloat = 15
        static let internalVerticalPadding: CGFloat = 15
        static let favButtonTrailing: CGFloat = 15
#endif
    }
    
    struct ProgramView {
#if os(tvOS)
        static let internalHorizontalPadding: CGFloat = 15
        static let internalVerticalPadding: CGFloat = 15
        static var width: CGFloat = 320
        static let height : CGFloat = AppStyle.rowHeight
        static let programSpacing: CGFloat = 15
#else
        static var width: CGFloat = 260
        static let height : CGFloat = AppStyle.rowHeight
        static let internalHorizontalPadding: CGFloat = 15
        static let internalVerticalPadding: CGFloat = 15
#endif
    }

    struct ProgramCarousel {
#if os(tvOS)
        static let channelNameBottomPadding: CGFloat = 40
#else
        static let channelNameBottomPadding: CGFloat = 20
#endif
    }

    
    
    struct GuideView {
#if os(tvOS)
        static let programSpacing: CGFloat = 35
#else
        static let programSpacing: CGFloat = 15
#endif
        
        private static let focusGrowth: CGFloat = 5 // Fixed pixel growth
        
        static func scaleAmount(for size: CGSize, isFocused: Bool) -> CGFloat {
            guard isFocused else { return 1.0 }
            let minDimension = max(size.width, 1.0)
            let scaleFactor = (minDimension + focusGrowth) / minDimension
            return scaleFactor
        }
        
        static func foregroundColor(isFocused: Bool) -> Color {
            if isFocused {
                return .guideForegroundFocused
            } else {
                return .guideForegroundNoFocus
            }
        }
        
        static func backgroundColor(isFocused: Bool, isPlaying: Bool, isProgramNow: Bool) -> Color {
            if isProgramNow {
                return .programNowPlayingBackground
            } else if isFocused {
                return .guideBackgroundFocused
            } else {
                return isPlaying ? .guideSelectedChannelBackground : .guideBackgroundNoFocus
            }
        }
    }
    
    struct Fonts {
        
        static var programViewFont: Font {
#if os(tvOS)
            .subheadline
#else
            .subheadline
#endif
        }
        
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

