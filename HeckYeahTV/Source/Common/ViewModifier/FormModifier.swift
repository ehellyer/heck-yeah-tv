//
//  FormModifier.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/13/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct FormModifier: ViewModifier {

    init(backgroundColor: UIColor?) {
        UITableView.appearance().backgroundColor = backgroundColor
    }

    func body(content: Content) -> some View {
        content
    }
}

extension Form {
    
    func backgroundColor(_ backgroundColor: Color?) -> some View {
        self.modifier(FormModifier(backgroundColor: UIColor(backgroundColor ?? .white)))
    }
    
}
