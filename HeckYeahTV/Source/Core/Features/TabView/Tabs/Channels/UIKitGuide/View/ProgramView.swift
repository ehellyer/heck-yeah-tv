//
//  ProgramView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

class ProgramView: CrossPlatformView {
    
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
        layer.cornerRadius = GuideRowCell.viewCornerRadius
        isUserInteractionEnabled = true
        clipsToBounds = true
        
        // Bootstrap the lazy loading.
        stackContainerView.bgColor = .clear
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(titleLabel)
        self.addGestureRecognizer(longTapGesture)
        self.widthAnchor.constraint(equalToConstant: 260).isActive = true
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Private API - View lazy binding.
    
    private lazy var stackContainerView: CrossPlatformView = {
        let view = PlatformUtils.createView()
        addSubview(view)
        view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        return view
    }()
    private lazy var stackView: PlatformStackView = {
        let view = PlatformUtils.createStackView(axis: .vertical)
        stackContainerView.addSubview(view)
        view.leadingAnchor.constraint(equalTo: stackContainerView.leadingAnchor, constant: 0).isActive = true
        stackContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
        view.topAnchor.constraint(equalTo: stackContainerView.topAnchor, constant: 0).isActive = true
        stackContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor, constant: 0).isActive = true
        view.distribution = .fill
        view.alignment = .fill
        view.spacing = 2
        return view
    }()
    private lazy var titleLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.lineLimit = 3
        label.font = AppStyle.Fonts.programTitleFont
        label.textColor = PlatformColor(named: "GuideForegroundNoFocus")
        return label
    }()
    private lazy var timeLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = AppStyle.Fonts.programTimeFont
        label.textColor = PlatformColor(named: "GuideForegroundNoFocus")
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 1
        return label
    }()
    private lazy var longTapGesture: PlatformPressGestureRecognizer = {
        let gesture = PlatformPressGestureRecognizer(target: self, action: #selector(viewTapped))
        gesture.cancelsTouchesInView = false
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = 12
        return gesture
    }()
    
    //MARK: - Private API - Actions and action view modifiers
    
    @objc private func viewTapped(_ gesture: PlatformPressGestureRecognizer) {
        switch gesture.state {
            case .began:
                onTapDownFocusEffect()

            case .ended, .changed, .cancelled, .failed:
                onTapUpFocusEffect()

                if gesture.state == .ended {
                    //TODO: Not yet implemented.  Put code here to send a message to the delegate to present information about the program.
                }
            default:
                break
        }
    }
    
    //MARK: - Private API
    
    private var channelId: ChannelId?
    private var program: Program?
    
    private func updateViewTintColor(_ color: UIColor) {
        titleLabel.textColor = color
        timeLabel.textColor = color
    }
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?
    
    func configure(with program: Program?, channelId: ChannelId?, isPlaying: Bool) {
        self.channelId = channelId
        self.program = program
        bgColor = (isPlaying) ? PlatformColor(named: "GuideSelectedChannelBackground") : PlatformColor(named: "GuideBackgroundNoFocus")
        titleLabel.textValue = program?.title
        timeLabel.textValue = program?.timeSlot
    }
}

extension ProgramView: FocusTargetView {
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if (context.nextFocusedView === self) {
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator) { [weak self] color in
                self?.updateViewTintColor(color)
            }
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator) { [weak self] color in
                self?.updateViewTintColor(color)
            }
        }
    }
}
