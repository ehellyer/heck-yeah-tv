//
//  FavoritesToggleView.swift
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
class FavoritesToggleView: PlatformView, FocusTargetView {
    
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

        self.addGestureRecognizer(longTapGesture)
        refreshView()
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
                delegate?.didBecomeFocused(target: FocusTarget.guide(channelId: channel.id, col: 0))
            }
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
        }
    }
    
    //MARK: - Private API - View Lazy Binding
    
    private lazy var imageView: PlatformImageView = {
        let view = PlatformUtils.createImageView()
        addSubview(view)
        view.widthAnchor.constraint(equalToConstant: 60).isActive = true
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 60)
        heightConstraint.priority = .defaultLow
        heightConstraint.isActive = true
        view.contentMode = .scaleAspectFit
        view.tintColor = .white
        
        view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        return view
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
                    delegate?.toggleFavoriteChannel(channel)
                }
                
            default:
                break
        }
    }
    
    //MARK: - Private API

    private var channel: GuideChannel?
    private var isSelectedChannel: Bool = false
    private var isFavorite: Bool = false
    
    private func channelFavoriteImage() -> UIImage? {
        let imageName = isFavorite ? "star.fill" : "star"
        
        let image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate)
        return image
    }
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?

    func refreshView() {
        imageView.image = channelFavoriteImage()
        imageView.tintColor = self.isFavorite ? .systemYellow : .white
        backgroundColor = (isSelectedChannel) ? PlatformColor(named: "selectedChannelColor") : PlatformColor(named: "guideBackgroundNoFocusColor")
    }
    
    func configure(with channel: GuideChannel, isSelectedChannel: Bool) {
        self.isSelectedChannel = isSelectedChannel
        self.channel = channel
        self.isFavorite = channel.isFavorite
        refreshView()
    }
}

