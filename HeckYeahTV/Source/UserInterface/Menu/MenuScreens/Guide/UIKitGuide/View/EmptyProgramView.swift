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
        
        addGestureRecognizer(longTapGesture)
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
    
    
    private func updateViewTintColor(_ color: UIColor) {
        titleLabel.textColor = color
    }
    
    private lazy var longTapGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(viewTapped))
        gesture.cancelsTouchesInView = false
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = 12
        return gesture
    }()
    
    //MARK: - Private API - Actions and action view modifiers
    
    @objc private func viewTapped(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
            case .began:
                onTapDownFocusEffect()
                
            case .ended, .changed, .cancelled, .failed:
                onTapUpFocusEffect()
                
            default:
                break
        }
    }
    
    //MARK: - Internal API
    
    func configure(isPlaying: Bool, isLoading: Bool) {
        titleLabel.text = isLoading ? "" : "No Guide Information"
        backgroundColor = (isPlaying) ? .guideSelectedChannelBackground : .guideBackgroundNoFocus
    }
}

//MARK: - tvOS Focus overrides

extension EmptyProgramView: @MainActor FocusTargetView {
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if (context.nextFocusedView === self) {
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator) {
                [weak self] foregroundColor, backgroundColor in
                self?.updateViewTintColor(foregroundColor)
            }
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator) {
                [weak self] foregroundColor, backgroundColor in
                self?.updateViewTintColor(foregroundColor)
            }
        }
    }
}




#Preview {
    let view = EmptyProgramView()
    view.configure(isPlaying: false, isLoading: false)
    
    let heightConstraint = view.heightAnchor.constraint(equalToConstant: AppStyle.rowHeight)
    heightConstraint.priority = UILayoutPriority(999)
    heightConstraint.isActive = true
    
    let widthConstraint = view.widthAnchor.constraint(equalToConstant: 350)
    widthConstraint.priority = UILayoutPriority(999)
    widthConstraint.isActive = true
    
    return view
}
