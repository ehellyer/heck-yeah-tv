//
//  EmptyProgramView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

class EmptyProgramView: CrossPlatformView {
    
    //MARK: - PlatformView Overrides
    
//    deinit {
//        logDebug("Deallocated")
//    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.masksToBounds = true
        layer.cornerRadius = 25
        isUserInteractionEnabled = true
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        
        tag = Self.viewTypeTagId
        self.addSubview(timeLabel)
        
        // Must be centered.
        self.centerXAnchor.constraint(equalTo: timeLabel.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor).isActive = true
        
        // Try not to blow label out the sides
        let leadingConstraint = timeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 20)
        leadingConstraint.priority = .init(900)
        leadingConstraint.isActive = true
        let trailingConstraint = timeLabel.trailingAnchor.constraint(greaterThanOrEqualTo: self.trailingAnchor, constant: 20)
        trailingConstraint.priority = .init(900)
        trailingConstraint.isActive = true
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    static let viewTypeTagId: Int = 923456899
    
    //MARK: - Private API - View lazy binding.
    
    private lazy var timeLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = AppStyle.Fonts.programTimeFont
        label.textColor = .white
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 1
        return label
    }()
    
    //MARK: - Internal API
    
    func configure(isPlaying: Bool, isLoading: Bool) {
        timeLabel.textValue = isLoading ? "" : "No Guide Information"
        bgColor = (isPlaying) ? PlatformColor(named: "selectedChannel") : PlatformColor(named: "guideBackgroundNoFocus")
    }
    
    func fillSuperview() {
        guard let superview = self.superview else {
            logDebug("Warning: fillSuperview() called before adding to superview")
            return
        }
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: superview.topAnchor),
            self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 20),
            superview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 30),
            self.bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        ])
        
        self.setContentHuggingPriority(.init(1), for: .horizontal)
        self.setContentHuggingPriority(.init(1), for: .vertical)
    }
}

extension EmptyProgramView {
    
    override var canBecomeFocused: Bool {
        return false
    }
}
