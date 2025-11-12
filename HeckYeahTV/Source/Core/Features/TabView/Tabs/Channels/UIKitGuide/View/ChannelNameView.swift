//
//  ChannelNameView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

@MainActor
class ChannelNameView: CrossPlatformView {

    //MARK: - PlatformView Overrides
    
//    deinit {
//        logDebug("Deallocated")
//    }

    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgColor = PlatformColor(named: "GuideBackgroundNoFocus")

        layer.masksToBounds = true
        layer.cornerRadius = GuideRowCell.viewCornerRadius
        clipsToBounds = true
        addGestureRecognizer(longTapGesture)
        addChannelInfoStackView()
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    //MARK: - Private API - View Lazy Binding
    
    private func addChannelInfoStackView() {
        addSubview(channelInfoStackView)
        channelInfoStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        trailingAnchor.constraint(equalTo: channelInfoStackView.trailingAnchor, constant: 20).isActive = true
        channelInfoStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        bottomAnchor.constraint(equalTo: channelInfoStackView.bottomAnchor, constant: 20).isActive = true
    }
    
    private lazy var channelInfoStackView: PlatformStackView = {
        let stackView = PlatformUtils.createStackView(axis: .vertical)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.alignment = .leading
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subTextStackView)
//        stackView.addArrangedSubview(logoImageView)
        return stackView
    }()
    
    private lazy var subTextStackView: PlatformStackView = {
        let stackView = PlatformUtils.createStackView(axis: .horizontal)
        stackView.alignment = UIStackView.Alignment.center
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.distribution = .fill
        stackView.addArrangedSubview(numberLabel)
        stackView.addArrangedSubview(qualityImageView)
        return stackView
    }()
    
    private lazy var titleLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = AppStyle.Fonts.titleFont
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.lineLimit = 1
        return label
    }()
    
    private lazy var numberLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = AppStyle.Fonts.subtitleFont
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.lineLimit = 1
        return label
    }()
    
    private lazy var qualityImageView: PlatformImageView = {
        let imageView = PlatformUtils.createImageView()
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var logoImageView: PlatformImageView = {
        let imageView = PlatformUtils.createImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.setContentHuggingPriority(.required, for: .vertical)
        return imageView
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
                if gesture.state == .ended, let channelId {
                    delegate?.selectChannel(channelId)
                }
                
            default:
                break
        }
    }
    
    //MARK: - Private API
    
    private var channelId: ChannelId?
    
    private func updateViewTintColor(_ color: UIColor) {
        titleLabel.textColor = color
        numberLabel.textColor = color
        qualityImageView.tintColor = color
    }
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?
    
    func configure(with channel: IPTVChannel?, isPlaying: Bool) {
        self.channelId = channel?.id
        bgColor = (isPlaying) ? PlatformColor(named: "GuideSelectedChannelBackground") : PlatformColor(named: "GuideBackgroundNoFocus")
        
        titleLabel.textValue = channel?.title ?? " "
        numberLabel.textValue = channel?.number ?? " "
        qualityImageView.image = channel?.quality.image
        
        if qualityImageView.image != nil {
            numberLabel.textValue = numberLabel.textValue?.trim()
        }
    }
}

extension ChannelNameView: @MainActor FocusTargetView {
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
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
