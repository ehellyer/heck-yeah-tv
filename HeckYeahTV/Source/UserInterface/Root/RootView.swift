//
//  RootView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 8/22/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//


import SwiftUI

struct RootView: View {
    @Binding var isBootComplete: Bool
    
    @State private var swiftDataController: BaseSwiftDataController = InjectedValues[\.swiftDataController]
    
    var body: some View {
        BootGateView(isBootComplete: $isBootComplete) {
            MainAppContentView()
                .modelContext(swiftDataController.viewContext)
#if os(macOS)
                .frame(minWidth: 900, minHeight: 507)
#endif
        }
    }
}
