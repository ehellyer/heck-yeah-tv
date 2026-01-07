//
//  IndicatorView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/8/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct IndicatorView: View {
    let totalCount: Int
    @Binding var currentIndex: Int?
    

    // Define how many dots are visible at one time
    let visibleDotsLimit = 10
    
    // Define the range of dots to show around the current index
    var lowerBound: Int {
        max(0, (currentIndex ?? 0) - visibleDotsLimit / 2)
    }
    var upperBound: Int {
        min(totalCount - 1, (currentIndex ?? 0) + visibleDotsLimit / 2)
    }
    
    
    var body: some View {
        
        HStack(alignment: .center) {
            if lowerBound > 0 {
                Text("...")
                    .foregroundColor(Color.gray.opacity(0.5))
            }
            
            ForEach(lowerBound...upperBound, id: \.self) { index in
                Button {
                    withAnimation {
                        currentIndex = index
                    }
                } label: {
                    Circle()
                        .fill(index == currentIndex ? Color.white : Color.gray.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                        .animation(.spring(), value: currentIndex)
                }
                .buttonStyle(.plain)
            }
            
            if upperBound < totalCount - 1 {
                Text("...")
                    .foregroundColor(Color.gray.opacity(0.5))
            }
        }
    }
}


#Preview {
    @Previewable @State var totalCount: Int = 10
    @Previewable @State var currentIndex: Int? = 0
    
    IndicatorView(totalCount: totalCount, currentIndex: $currentIndex)
}
