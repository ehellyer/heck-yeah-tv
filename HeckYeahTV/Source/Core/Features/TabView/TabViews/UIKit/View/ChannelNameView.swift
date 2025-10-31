//
//  ChannelNameView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

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
        
        bgColor = PlatformColor(named: "guideBackgroundNoFocus")

#if canImport(AppKit)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 25
#else
        layer.masksToBounds = true
        layer.cornerRadius = 25
#endif
        clipsToBounds = true
        
        channelInfoStackView.widthAnchor.constraint(equalToConstant: 300).isActive = true
        self.addGestureRecognizer(longTapGesture)
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
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
#if canImport(AppKit)
        stackView.alignment = NSLayoutConstraint.Attribute.centerX
#else
        stackView.alignment = UIStackView.Alignment.center
#endif
        stackView.setContentHuggingPriority(.required, for: .vertical)
        stackView.distribution = .fill
        stackView.addArrangedSubview(numberLabel)
        return stackView
    }()
    
    private lazy var titleLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 34, weight: .semibold)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.lineLimit = 1
        return label
    }()
    
    private lazy var numberLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 32)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.textColor = .white
        label.lineLimit = 1
        return label
    }()
    
    private lazy var logoImageView: PlatformImageView = {
        let imageView = PlatformUtils.createImageView()
        
#if canImport(AppKit)
        imageView.imageScaling = .scaleProportionallyUpOrDown
#else
        imageView.contentMode = .scaleAspectFit
#endif
        imageView.widthAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        imageView.setContentHuggingPriority(.required, for: .vertical)
        return imageView
    }()
    
    private lazy var longTapGesture: PlatformPressGestureRecognizer = {
        let gesture = PlatformPressGestureRecognizer(target: self, action: #selector(viewTapped))
#if canImport(UIKit)
        gesture.cancelsTouchesInView = false
#endif
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = 12
        return gesture
    }()
    
    //MARK: - Private API - Actions and action view modifiers
    
    @objc private func viewTapped(_ gesture: PlatformPressGestureRecognizer) {
        switch gesture.state {
            case .began:
#if os(tvOS)
                onTapDownFocusEffect()
#else
                break
#endif
                
            case .ended, .changed, .cancelled, .failed:
#if os(tvOS)
                onTapUpFocusEffect()
#endif
                if gesture.state == .ended, let channelId {
                    delegate?.selectChannel(channelId)
                }
                
            default:
                break
        }
    }
    
    //MARK: - Private API
    
    private var channelId: ChannelId?

    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?
    
    func configure(with channel: IPTVChannel?, isPlaying: Bool) {
        self.channelId = channel?.id
        subTextStackView.viewWithTag(StreamQualityView.viewTypeTagId)?.removeFromSuperview()
        bgColor = (isPlaying) ? PlatformColor(named: "selectedChannel") : PlatformColor(named: "guideBackgroundNoFocus")
        
        titleLabel.textValue = channel?.title ?? " "
        numberLabel.textValue = channel?.number ?? " "
        
        if let channel, channel.quality != .unknown {
            subTextStackView.addArrangedSubview(channel.quality.legacyView)
            numberLabel.textValue = numberLabel.textValue?.trim()
        }
    }
}

#if os(tvOS)
extension ChannelNameView: @MainActor FocusTargetView {
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        logDebug("shouldUpdateFocusInContext")
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if (context.nextFocusedView === self) {
//            if let channelId {
//                delegate?.didBecomeFocused(target: FocusTarget.guide(channelId: channelId, col: 1))
//            }
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
        }
    }
}
#endif
