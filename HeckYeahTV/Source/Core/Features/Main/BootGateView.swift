//
//  BootGateView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/25/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct BootGateView<T: View>: View {
    
    @Binding var isBootComplete: Bool
    @State var minimumDelayElapsed: Bool = false
    let mainAppContent: () -> T
    
    var body: some View {
        
        if isBootComplete && minimumDelayElapsed {
            self.mainAppContent()
        } else {
            BootSplashView()
                .id("BootSplashView")
                .allowsHitTesting(false)
                .task {
                    try? await Task.sleep(nanoseconds: 4_500_000_000)
                    minimumDelayElapsed = true
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut(duration: 0.35), value: (isBootComplete && minimumDelayElapsed))
        }
    }
}
