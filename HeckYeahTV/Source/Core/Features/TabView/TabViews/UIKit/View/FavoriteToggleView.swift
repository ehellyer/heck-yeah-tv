//
//  FavoriteToggleView.swift
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
class FavoriteToggleView: CrossPlatformView {
    
    //MARK: - PlatformView Overrides
    
//    deinit {
//        logDebug("Deallocated")
//    }

    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

#if os(macOS)
        wantsLayer = true
        layer?.masksToBounds = true
        layer?.cornerRadius = 25
#else
        layer.masksToBounds = true
        layer.cornerRadius = 25
        isUserInteractionEnabled = true
#endif
        clipsToBounds = true

        self.addGestureRecognizer(longTapGesture)
#if os(tvOS)
        self.addGestureRecognizer(leftSwipeGesture)
#endif
        self.configure(with: nil, isPlaying: false)
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    //MARK: - Private API - View Lazy Binding
    
    private lazy var imageView: PlatformImageView = {
        let view = PlatformUtils.createImageView()
        addSubview(view)
        view.widthAnchor.constraint(equalToConstant: 60).isActive = true
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 60)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
#if !os(macOS)
        view.contentMode = .scaleAspectFit
        view.tintColor = .white
#endif
        
        view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        return view
    }()
    
    private lazy var longTapGesture: PlatformPressGestureRecognizer = {
        let gesture = PlatformPressGestureRecognizer(target: self, action: #selector(viewTapped))
#if !os(macOS)
        gesture.cancelsTouchesInView = false
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = 12
#else
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = 12
#endif
        return gesture
    }()
    
#if os(tvOS)
    private lazy var leftSwipeGesture: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(leftSwipeDetected))
        gesture.direction = .left
        return gesture
    }()
#endif
    
    //MARK: - Private API - Actions and action view modifiers
    
    @objc private func viewTapped(_ gesture: PlatformPressGestureRecognizer) {
        switch gesture.state {
            case .began:
#if os(tvOS)
                onTapDownFocusEffect()
#endif
            case .ended, .changed, .cancelled, .failed:
#if os(tvOS)
                onTapUpFocusEffect()
#endif
                if gesture.state == .ended, let channelId {
                    delegate?.toggleFavoriteChannel(channelId)
                }
            default:
                break
        }
    }
    
#if os(tvOS)
    @objc private func leftSwipeDetected(_ gesture: UISwipeGestureRecognizer) {
        guard gesture.state == .ended else { return }
        logDebug("Left swipe detected on Siri remote")
        delegate?.didBecomeFocused(target: FocusTarget.favoritesToggle)
    }
#endif
    
    //MARK: - Private API

    private var channelId: ChannelId?
    
    private func updateLoadingState(isLoading: Bool) {
        if isLoading {
            longTapGesture.isEnabled = false
        } else {
            longTapGesture.isEnabled = true
        }
    }

    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?

    func configure(with channel: IPTVChannel?, isPlaying: Bool) {
        self.channelId = channel?.id
        let isFavorite = (channel?.isFavorite == true)
        bgColor = (isPlaying) ? PlatformColor(named: "selectedChannel") : PlatformColor(named: "guideBackgroundNoFocus")
#if !os(macOS)
        if (channel == nil) {
            imageView.layer.opacity = 0.0
        } else {
            imageView.layer.opacity = 1.0
            imageView.tintColor = (isFavorite) ? .systemYellow : .white
        }
        
        let imageName = isFavorite ? "star.fill" : "star"
        imageView.image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate)
#endif
    }
}

#if os(tvOS)
extension FavoriteToggleView: FocusTargetView {
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if (context.nextFocusedView === self) {
//            if let channelId {
//                delegate?.didBecomeFocused(target: FocusTarget.guide(channelId: channelId, col: 0))
//            }
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
        }
    }
}
#endif
