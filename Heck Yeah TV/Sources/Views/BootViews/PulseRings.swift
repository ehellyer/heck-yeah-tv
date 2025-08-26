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
        TimelineView(.animation) { ctx in
            Canvas { context, size in
                let t = ctx.date.timeIntervalSinceReferenceDate
                let base = t.remainder(dividingBy: 1.6) // cycle
                let maxR = min(size.width, size.height) * 0.48
                for i in 0..<4 {
                    let phase = (base + Double(i) * 0.4).remainder(dividingBy: 1.6) / 1.6
                    let r = maxR * phase
                    let alpha = (1 - phase)
                    let rect = CGRect(x: size.width/2 - r,
                                      y: size.height/2 - r,
                                      width: r * 3,
                                      height: r * 4)
                    
                    let stroke = StrokeStyle(lineWidth: max(2, 6 * alpha),
                                             lineCap: .round)
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(0.28 * alpha)),
                        style: stroke
                    )
                }
            }
        }
    }
}

#Preview() {
    PulsingRings()
}
