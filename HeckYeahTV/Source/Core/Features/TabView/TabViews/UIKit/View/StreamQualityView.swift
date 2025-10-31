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

@MainActor
extension StreamQuality {
    var legacyView: StreamQualityView {
        return StreamQualityView(streamQuality: self)
    }
}

@MainActor
class StreamQualityView: PlatformView {
    
//    deinit {
//        logDebug("Deallocated")
//    }
    
    init(streamQuality: StreamQuality) {
        super.init(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        self.translatesAutoresizingMaskIntoConstraints = false
        self.clipsToBounds = false
        
        self.commonInit(sq: streamQuality)
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    private func commonInit(sq: StreamQuality) {
        
#if os(macOS)
        identifier = NSUserInterfaceItemIdentifier(rawValue: "\(Self.viewTypeTagId)")
#else
        tag = Self.viewTypeTagId
#endif
        
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .white
        label.textValue = sq.name
        
        self.addSubview(label)
        label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 5).isActive = true
        self.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 5).isActive = true
        label.topAnchor.constraint(equalTo: self.topAnchor, constant: 3).isActive = true
        self.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 3).isActive = true
        
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.required, for: .vertical)
        self.setContentCompressionResistancePriority(.required, for: .horizontal)

#if os(macOS)
        self.wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = PlatformColor.white.cgColor
        layer?.masksToBounds = false
        layer?.backgroundColor = PlatformColor.clear.cgColor
#else
        layer.cornerRadius = 6
        layer.borderWidth = 1
        layer.borderColor = PlatformColor.white.cgColor
        layer.masksToBounds = false
        self.backgroundColor = PlatformColor.clear
#endif
    }
    
    static let viewTypeTagId: Int = 23456604455
}
