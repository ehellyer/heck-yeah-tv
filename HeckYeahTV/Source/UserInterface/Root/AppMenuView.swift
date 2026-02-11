//
//  AppMenuView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/10/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct AppMenuView: View {

    var body: some View {
#if os(tvOS)
        // App Menu for tvOS
        MenuTabView()
            .background(.clear)
#else
        // App Menu for iOS/macOS
        MenuPickerView()
            .background(.clear)
#endif
    }
}
