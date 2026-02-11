//
//  TVPreviewView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 12/17/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct TVPreviewView<T: View>: View {

    init(contentView: @escaping () -> T) {
        logDebug("Init Starting")
        self.contentView = contentView
    }
    
    private let contentView: () -> T
    
    var body: some View {
        ZStack {
            // Adds an image in the background to simulated TV stream for previews.
            // Thew Image asset catalog has versions to match preview device and orientations.
            // The purpose is to help visualize how transparency effects look over a TV stream.
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
