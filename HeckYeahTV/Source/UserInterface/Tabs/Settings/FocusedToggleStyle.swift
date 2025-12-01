//
//  FocusedToggleStyle.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/24/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct FocusedToggleStyle: ToggleStyle {

    @Environment(\.isFocused) private var isFocused

#if !os(tvOS)
    private let width: CGFloat = 45
    private let height: CGFloat = 25
    private let halfHeight: CGFloat = 12.5
#else
    private let width: CGFloat = 50
    private let height: CGFloat = 32
    private let halfHeight: CGFloat = 16
#endif
    
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                    .foregroundColor(isFocused ?
                        .guideForegroundFocused : .guideForegroundNoFocus)
                Spacer()
                
                // Switch Only
                RoundedRectangle(cornerRadius: halfHeight)
                    .fill(configuration.isOn ? Color.mainAppTheme : .toggleOffBackground)
                    .overlay(
                        Circle()
                            .foregroundColor(.white)
                            .padding(.all, 3)
                            .overlay(
                                Image(systemName: configuration.isOn ? "checkmark" : "xmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 11,
                                           height: 11,
                                           alignment: .center)
                                    .foregroundColor(.toggleOffBackground)
                            )
                            .offset(x: configuration.isOn ? 10 : -10, y: 0)
                    )
                    .animation(.easeOut(duration: 0.2),
                               value: configuration.isOn)

                    .frame(width: width, height: height, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(
                Capsule()
                    .fill(isFocused ? .guideBackgroundFocused : .guideBackgroundNoFocus)
            )
        }        
        .buttonStyle(.plain)
        .onChange(of: isFocused) { oldValue, newValue in
            if isFocused {
                logDebug("ToggleView Focused")
            } else {
                logDebug("ToggleView lost focus")
            }
        }
    }
}

// MARK: - Previews

#Preview("ToggleView") {
    
    @Previewable @State var toggleIsOn: Bool = false
    
    VStack {
        Spacer()
        Toggle("Toggle View", isOn: $toggleIsOn)
            .toggleStyle(FocusedToggleStyle())
        Spacer()
    }
    .padding()
 
    .background(.clear)//Color(red:0.9, green:0.9, blue:0.9, opacity:1.0))
}
