//
//  ChannelNameView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
class ChannelNameView: PlatformView, FocusTargetView {
    
    //MARK: - PlatformView Overrides
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = PlatformColor(named: "guideBackgroundNoFocusColor")
        layer.cornerRadius = 25
        layer.masksToBounds = true
        isUserInteractionEnabled = true
        clipsToBounds = true
        
        channelInfoStackView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        self.addGestureRecognizer(longTapGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if (context.nextFocusedView === self) {
            if let channel {
                
                delegate?.didBecomeFocused(target: FocusTarget.guide(channelId: channel.id, col: 1))
            }
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
        }
    }
    
    func focusImmediately(_ view: UIView, from env: UIFocusEnvironment) {
        guard view.canBecomeFocused else { return }
        // Get the focus system for this environment (API is deprecated on newer SDKs; use #available if needed)
        if let system = UIFocusSystem.focusSystem(for: env) {
            system.requestFocusUpdate(to: view)
            system.updateFocusIfNeeded()
        }
    }
    
    //MARK: - Private API - View Lazy Binding
    
    private lazy var channelInfoStackView: PlatformStackView = {
        let stackView = PlatformUtils.createStackView(axis: .vertical)
        addSubview(stackView)
        stackView.setContentCompressionResistancePriority(.required, for: .vertical)
        stackView.alignment = .leading
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subTextStackView)
//        stackView.addArrangedSubview(logoImageView)
        stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20).isActive = true
        trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 20).isActive = true
        stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 20).isActive = true
        bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20).isActive = true
        return stackView
    }()
    private lazy var subTextStackView: PlatformStackView = {
        let stackView = PlatformUtils.createStackView(axis: .horizontal)
        stackView.alignment = .center
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.distribution = .fill
        stackView.addArrangedSubview(numberLabel)
        return stackView
    }()
    private lazy var titleLabel: PlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 34, weight: .semibold)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()
    private lazy var numberLabel: PlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 32)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.numberOfLines = 1
        return label
    }()
    private lazy var logoImageView: PlatformImageView = {
        let imageView = PlatformUtils.createImageView()
        imageView.contentMode = .scaleAspectFit
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
                if gesture.state == .ended, let channel {
                    delegate?.selectChannel(channel)
                }
                
            default:
                break
        }
    }
    
    //MARK: - Private API
    
    private var channel: IPTVChannel?
    private var isSelectedChannel: Bool = false
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?
    
    func refreshView() {
        guard let channel else { return }
        titleLabel.text = channel.title
        numberLabel.text = channel.number
        subTextStackView.viewWithTag(StreamQuality.streamQualityViewTagId)?.removeFromSuperview()
        if channel.quality != .unknown {
            subTextStackView.addArrangedSubview(channel.quality.legacyView)
        }
    }
    
    func configure(with channel: IPTVChannel) {
        self.isSelectedChannel = channel.isPlaying
        self.channel = channel
        backgroundColor = (isSelectedChannel) ? PlatformColor(named: "selectedChannelColor") : PlatformColor(named: "guideBackgroundNoFocusColor")
        refreshView()
    }
}
