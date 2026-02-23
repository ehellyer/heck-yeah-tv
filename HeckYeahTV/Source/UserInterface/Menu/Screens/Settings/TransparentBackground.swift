//
//  TransparentBackground.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 2/11/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import UIKit
import SwiftUI

// (: :) Hack to make parts of SwiftUI to style the way I want it to look, not the way some Apple engineer wants it to look.  Good grief Ed, this is awful! (: :)
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
