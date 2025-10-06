//
//  StreamQualityView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/19/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension StreamQuality {
    
    var legacyView: PlatformView {
        let view = PlatformUtils.createView()
        view.tag = StreamQuality.streamQualityViewTagId
        view.layer.cornerRadius = 6
        view.layer.borderWidth = 1
        view.layer.borderColor = PlatformColor.white.cgColor
        view.layer.masksToBounds = false
        
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .white
        label.text = name
        
        view.addSubview(label)
        label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 5).isActive = true
        view.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5).isActive = true
        label.topAnchor.constraint(equalTo: view.topAnchor, constant: 3).isActive = true
        view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 3).isActive = true
        
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }
}

