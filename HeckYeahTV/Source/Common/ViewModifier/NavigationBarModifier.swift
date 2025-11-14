//
//  NavigationBarModifier.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 11/13/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

struct NavigationBarModifier: ViewModifier {
    var backgroundColor: UIColor?

    init(backgroundColor: UIColor?, tintColor: UIColor?) {
        self.backgroundColor = backgroundColor

        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithTransparentBackground()
        coloredAppearance.backgroundColor = backgroundColor ?? .clear
        coloredAppearance.titleTextAttributes = [.foregroundColor: tintColor as Any]
        coloredAppearance.largeTitleTextAttributes = [.foregroundColor: tintColor as Any]

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
        UINavigationBar.appearance().tintColor = tintColor
    }

    func body(content: Content) -> some View {
        ZStack{
            Rectangle()
                .fill(Color(backgroundColor ?? .clear))
                .edgesIgnoringSafeArea(.all)
            content
        }
    }
}

extension View {
    
    func navigationBarColor(_ backgroundColor: Color?, tintColor: Color?) -> some View {
        self.modifier(NavigationBarModifier(backgroundColor: UIColor(backgroundColor ?? .white), tintColor: UIColor(tintColor ?? .black)))
    }
}
