//
//  RootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/18/25.
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
                VLCPlayerWrapperView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

#Preview {
    RootView(hidePlayer: true)
}
