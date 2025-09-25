//
//  PulseRings.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct PulsingRings: View {
    
    var body: some View {
        TimelineView(.animation) { tlvContext in
            Canvas { gContext, size in
                let t = tlvContext.date.timeIntervalSinceReferenceDate
                let base = t.remainder(dividingBy: 4.0)
                let maxR = min(size.width, size.height) * 0.6
                for i in -8..<4 {
                    let phase = (base + Double(i).remainder(dividingBy: 1.6) / 1.6)
                    let r = maxR * phase
                    let alpha = (1 - phase)
                    
                    let rect = CGRect(x: (size.width * 0.6) - r,
                                      y: (size.height * 0.6) - r,
                                      width: r * 20,
                                      height: r * 4)
                    
                    let stroke = StrokeStyle(lineWidth: 6 * alpha,
                                             lineCap: .round)
                    
                    gContext.stroke(Path(ellipseIn: rect),
                                    with: .color(.white.opacity(0.28 * alpha)),
                                    style: stroke)
                }
            }
        }
    }
}

#Preview("Original") {
    PulsingRings()
        .ignoresSafeArea()
        .background(Color.black)
}

