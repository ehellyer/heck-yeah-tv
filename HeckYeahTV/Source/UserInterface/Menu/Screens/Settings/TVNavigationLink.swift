//
//  TVNavigationLink.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/10/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

/// Custom navigation link to override the very opinionated built in styling.
struct TVNavigationLink<Label: View, Destination: View>: View {
    
    let label: Label
    let destination: Destination
    
    init(@ViewBuilder label: () -> Label, @ViewBuilder destination: () -> Destination) {
        self.label = label()
        self.destination = destination()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            NavigationLink(destination: destination) {
                EmptyView()
            }
            .opacity(0)
            
            HStack {
                label
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(white: 0.4))
                    .font(.system(size: 14, weight: .semibold))
            }
        }
    }
}
