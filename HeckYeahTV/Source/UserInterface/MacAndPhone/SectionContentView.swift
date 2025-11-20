//
//  SectionContentView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/8/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct SectionContentView<T: View>: View {
    
    let content: () -> T

    init(@ViewBuilder content: @escaping () -> T) {
        self.content = content
    }
    
    var body: some View {
        self.content()
    }
}
