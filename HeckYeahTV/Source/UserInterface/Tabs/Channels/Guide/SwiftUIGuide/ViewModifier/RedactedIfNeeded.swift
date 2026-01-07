//
//  RedactedIfNeeded.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/3/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct RedactedIfNeeded<T>: ViewModifier {
    let type: T?
    
    func body(content: Content) -> some View {
        if type == nil {
            content.redacted(reason: .placeholder)
        } else {
            content
        }
    }
}
