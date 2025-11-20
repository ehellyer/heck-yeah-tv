//
//  SettingsView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/31/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

struct SettingsView: View {
    let colors = ["Red", "Green", "Blue", "Yellow"]
    @State var selectedColor = "Red" // Bound to the Picker's selection

    var body: some View {

        VStack {
            Picker("Choose a color", selection: $selectedColor) { // Label and binding
                ForEach(colors, id: \.self) { color in
                    Text(color) // Content: Text views for each color
                }
            }
            Text("You selected: \(selectedColor)") // Displaying the selected value
        }
    }
}
