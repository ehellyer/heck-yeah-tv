//
//  BackgroundView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/21/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct BackgroundView: View {
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                Text("Heck\u{00A0}Yeah TV!")
                    .font(.system(size: 1000))
                    .minimumScaleFactor(0.01)
                    .lineLimit(1)
                    .frame(width: geometry.size.width,
                           height: geometry.size.height,
                           alignment: .center)
                    .foregroundColor(.white)
                    .shadow(color: Color(red: 0.5, green: 0.5, blue: 0.5), radius: 0, x: -2, y: -2)
                    .shadow(color: Color(red: 0.76, green: 0.76, blue: 0.76), radius: 0, x: 2, y: 2)
                    
            }
            .padding(EdgeInsets(top: 10, leading: 50, bottom: 10, trailing: 50))
        }
    }
}

#Preview() {
    BackgroundView()
}
