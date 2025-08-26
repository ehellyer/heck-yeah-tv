//
//  RootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct RootView: View {
    
    @State private var hidePlayer: Bool
    
    
    init(hidePlayer: Bool = false) {
        self.hidePlayer = hidePlayer
     
    }
    
    var body: some View {
        ZStack {
            
            if hidePlayer {
                BackgroundView()
            } else {
                Color.black.ignoresSafeArea(.all)
                GuideView()
                    .edgesIgnoringSafeArea(.all)
                    
            }
        }
    }
}

#Preview {
    RootView(hidePlayer: true)
}
