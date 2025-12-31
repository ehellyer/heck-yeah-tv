//
//  EmptyProgramView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

class EmptyProgramView: UIView {
    
    //MARK: - UIView Overrides
    
//    deinit {
//        logDebug("Deallocated")
//    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.masksToBounds = true
        layer.cornerRadius = GuideRowCell.viewCornerRadius
        isUserInteractionEnabled = true
        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        
        tag = Self.viewTypeTagId
        self.addSubview(titleLabel)
        
        // Must be centered.
        self.centerXAnchor.constraint(equalTo: titleLabel.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor).isActive = true
        
        // Try not to blow label out the sides
        let leadingConstraint = titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: self.leadingAnchor, constant: 20)
        leadingConstraint.priority = .init(900)
        leadingConstraint.isActive = true
        let trailingConstraint = titleLabel.trailingAnchor.constraint(greaterThanOrEqualTo: self.trailingAnchor, constant: 20)
        trailingConstraint.priority = .init(900)
        trailingConstraint.isActive = true
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    static let viewTypeTagId: Int = 923456899
    
    //MARK: - Private API - View lazy binding.
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppStyle.Fonts.programTimeSlotFont
        label.textColor = .white
        label.textAlignment = .center
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 1
        return label
    }()
    
    //MARK: - Internal API
    
    func configure(isPlaying: Bool, isLoading: Bool) {
        titleLabel.text = isLoading ? "" : "No Guide Information"
        backgroundColor = (isPlaying) ? .guideSelectedChannelBackground : .guideBackgroundNoFocus
    }
    
    func fillSuperview() {
        guard let superview = self.superview else {
            logDebug("Warning: fillSuperview() called before adding to superview")
            return
        }
        
        self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 20).isActive = true
        superview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 30).isActive = true
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        
        self.setContentHuggingPriority(UILayoutPriority(1), for: .horizontal)
        self.setContentHuggingPriority(UILayoutPriority(1), for: .vertical)
    }
}

extension EmptyProgramView {
    
    override var canBecomeFocused: Bool {
        return false
    }
}
