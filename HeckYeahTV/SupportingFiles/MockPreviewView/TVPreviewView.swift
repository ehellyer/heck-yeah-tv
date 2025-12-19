//
//  TVPreviewView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/17/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct TVPreviewView<T: View>: View {
    
    let contentView: () -> T
    
    var body: some View {
        ZStack {
            // Simulated TV stream background for previews
            Color.clear
                .overlay(
                    Image("PreviewTVScreenShot")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                )
                .ignoresSafeArea()
            
            Color.guideTransparency
                .ignoresSafeArea()
            
            self.contentView()
        }
    }
}
