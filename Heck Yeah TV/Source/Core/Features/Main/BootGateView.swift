//
//  BootGateView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/25/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct BootGateView<T: View>: View {
    
    @Binding var isReady: Bool
    @State var minimumDelayElapsed: Bool = false
    let mainAppContent: () -> T

    var body: some View {
        ZStack {
            if isReady && minimumDelayElapsed {
                self.mainAppContent()
            } else {
                BootSplashView()
                    .transition(.opacity.combined(with: .blurReplace).combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: (isReady && minimumDelayElapsed))
        .task {
            try? await Task.sleep(nanoseconds: 4_500_000_000)
            minimumDelayElapsed = true
            print("minimumDelayElapsed is true.  Channel fetch complete? \(isReady ? "yes" : "no")")
        }
    }
}
