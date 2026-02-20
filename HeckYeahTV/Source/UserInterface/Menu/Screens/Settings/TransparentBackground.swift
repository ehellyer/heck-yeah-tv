//
//  TransparentBackground.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/11/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import UIKit
import SwiftUI

struct TransparentBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        Task { @MainActor in
            view.superview?.superview?.backgroundColor = .clear
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
