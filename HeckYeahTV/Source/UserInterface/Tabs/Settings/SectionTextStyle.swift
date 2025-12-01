//
//  SectionTextStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/29/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct SectionTextStyle: ViewModifier {
    
    func body(content: Content) -> some View {
        content
#if os(tvOS)
            .foregroundColor(Color.white)
#else
            .foregroundColor(Color.primary)
#endif
    }
}


struct SectionTextContainerStyle: ViewModifier {
    
    func body(content: Content) -> some View {
        
#if os(tvOS)
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                Capsule()
                    .fill(.guideBackgroundNoFocus)
            )
#else
        content
#endif
    }
}
