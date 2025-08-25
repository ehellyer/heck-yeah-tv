//
//  RootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//

import SwiftUI

struct RootView: View {
    
    @State private var autoplay: Bool
    @State private var hidePlayer: Bool
    
    init(autoplay: Bool, hidePlayer: Bool = false) {
        self.autoplay = autoplay
        self.hidePlayer = hidePlayer
    }
    
    var body: some View {
        ZStack {
            Color.blue.edgesIgnoringSafeArea(.all)
            
            if !hidePlayer {
                VLCPlayerWrapperView(url: "https://cvtv.cvalley.net/hls/KQFXFOX/KQFXFOX.m3u8",
                                     autoplay: autoplay)
                    .edgesIgnoringSafeArea(.all)
            } else {
                BackgroundView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

#Preview {
    RootView(autoplay: false, hidePlayer: true)
}
