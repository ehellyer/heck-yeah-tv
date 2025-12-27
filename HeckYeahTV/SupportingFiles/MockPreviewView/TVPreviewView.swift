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
            // Simulated TV stream background for previews (Image has versions for device and orientations.)
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
