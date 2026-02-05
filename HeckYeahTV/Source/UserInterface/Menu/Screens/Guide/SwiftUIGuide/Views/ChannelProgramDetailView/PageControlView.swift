//
//  PageControlView.swift
//  HeckYeahTV
//
//  Created by Ed Hellyer on 1/9/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import SwiftUI

#if canImport(UIKit)
typealias PlatformPageControl = UIPageControl
#elseif canImport(AppKit)
typealias PlatformPageControl = AKPageControl
#endif

struct PageControlView: CrossPlatformRepresentable {
   
    var numberOfPages: Int
    
    var activePage: Int?
    
    var onPageChange: (Int) -> ()
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(onPageChange: onPageChange)
    }
    
    func makeView(context: Context) -> PlatformView {
        let view = PlatformPageControl()
#if canImport(UIKit)
        view.backgroundStyle = .prominent
        view.currentPageIndicatorTintColor = PlatformColor.white
        view.pageIndicatorTintColor = PlatformColor.white.withAlphaComponent(0.5)
        view.addTarget(context.coordinator,
                       action: #selector(Coordinator.onPageUpdate(control:)),
                       for: .valueChanged)

#elseif canImport(AppKit)
        view.onPageChange = context.coordinator.onPageChange
        // Set frame to ensure proper sizing
        view.frame = NSRect(x: 0, y: 0, width: 400, height: 40)
#endif
        view.numberOfPages = numberOfPages
        view.currentPage = activePage ?? 0
        return view
    }
    
    func updateView(_ view: PlatformView, context: Context) {
        /// Updating Outside Event Changes
        let pageControl = view as! PlatformPageControl
        pageControl.numberOfPages = numberOfPages
        pageControl.currentPage = activePage ?? 0
    }
    
    static func dismantleView(_ view: PlatformView, coordinator: Coordinator) {
        
    }
    
    class Coordinator: NSObject {
        
        var onPageChange: (Int) -> ()
        
        init(onPageChange: @escaping (Int) -> Void) {
            self.onPageChange = onPageChange
        }
        
        @objc func onPageUpdate(control: PlatformPageControl) {
            onPageChange(control.currentPage)
        }
    }
}

#Preview {
    @Previewable @State var currentPage: Int = 0
    ZStack(alignment: .bottom) {
        PageControlView(numberOfPages: 50,
                        activePage: currentPage,
                        onPageChange: { index in
            print("Page Changed \(index)")
        })
        .frame(height: 30)
        .padding(.bottom, 10)
    }
}
