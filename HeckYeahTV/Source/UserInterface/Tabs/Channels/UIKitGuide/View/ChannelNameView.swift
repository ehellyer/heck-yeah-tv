//
//  ChannelNameView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

@MainActor
class ChannelNameView: UIView {

    //MARK: - UIView Overrides
    
//    deinit {
//        logDebug("Deallocated")
//    }

    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .guideBackgroundNoFocus
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
    
    private lazy var channelInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.alignment = .leading
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subTextStackView)
//        stackView.addArrangedSubview(logoImageView)
        return stackView
    }()
    
    private lazy var subTextStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.alignment = .center
        stackView.addArrangedSubview(numberLabel)
        stackView.addArrangedSubview(qualityImageView)
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppStyle.Fonts.titleFont
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppStyle.Fonts.subtitleFont
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var qualityImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.setContentHuggingPriority(.required, for: .vertical)
        return imageView
    }()
    
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
        backgroundColor = (isPlaying) ? .guideSelectedChannelBackground : .guideBackgroundNoFocus
        
        titleLabel.text = channel?.title ?? " "
        numberLabel.text = channel?.number ?? " "
        qualityImageView.image = channel?.quality.image
        
        if qualityImageView.image != nil {
            numberLabel.text = numberLabel.text?.trim()
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
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator) { [weak self] foregroundColor, backgroundColor in
                self?.updateViewTintColor(foregroundColor)
            }
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator) { [weak self] foregroundColor, backgroundColor in
                self?.updateViewTintColor(foregroundColor)
            }
        }
    }
}
