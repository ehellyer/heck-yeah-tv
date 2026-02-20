//
//  MainTitleView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/13/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct MainTitleView: View {
    
    let title: String
    
    // Adaptive font sizes based on platform
    private var titleFontSize: CGFloat {
        AppStyle.BootSplashScreen.titleFontSize
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tv")
                .resizable()
                .scaledToFill()
                .foregroundStyle(Color.white.opacity(0.4))
                .frame(width: AppStyle.BootSplashScreen.imageFrame,
                       height: AppStyle.BootSplashScreen.imageFrame)
            
            Text(title)
                .font(.system(size: titleFontSize,
                              weight: .heavy,
                              design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    MainTitleView(title: "MyT Vision")
}

