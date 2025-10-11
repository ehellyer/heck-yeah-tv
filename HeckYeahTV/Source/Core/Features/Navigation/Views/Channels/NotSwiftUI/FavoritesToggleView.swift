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
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgColor = PlatformColor(named: "guideBackgroundNoFocusColor")

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
        refreshView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                if gesture.state == .ended, let channel {
                    delegate?.toggleFavoriteChannel(channel)
                }
            default:
                break
        }
    }
    
    //MARK: - Private API

    private var channel: IPTVChannel?
    private var isSelectedChannel: Bool = false
    private var isFavorite: Bool = false
    
#if !os(macOS)
    private func channelFavoriteImage() -> UIImage? {
        let imageName = isFavorite ? "star.fill" : "star"
        let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate)
        return image
    }
#endif
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?

    func refreshView() {
#if !os(macOS)
        imageView.image = channelFavoriteImage()
        imageView.tintColor = self.isFavorite ? .systemYellow : .white
#endif
        bgColor = (isSelectedChannel) ? PlatformColor(named: "selectedChannelColor") : PlatformColor(named: "guideBackgroundNoFocusColor")
    }
    
    func configure(with channel: IPTVChannel) {
        self.isSelectedChannel = channel.isPlaying
        self.channel = channel
        self.isFavorite = channel.isFavorite
        refreshView()
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
            if let channel {
                delegate?.didBecomeFocused(target: FocusTarget.guide(channelId: channel.id, col: 0))
            }
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
        }
    }
}
#endif
