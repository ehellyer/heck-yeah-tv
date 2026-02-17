//
//  FavoriteToggleView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

@MainActor
class FavoriteToggleView: UIView {
    
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

        self.addGestureRecognizer(longTapGesture)
        self.addGestureRecognizer(leftSwipeGesture)
        self.configure(with: nil, isPlaying: false)
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    //MARK: - Private API - View Lazy Binding
    
    private var width: CGFloat = 60.0
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: width)
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
    
    private lazy var leftSwipeGesture: UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(viewLeftSwipe))
        gesture.direction = .left
        return gesture
    }()
    
    private lazy var channelBundleId: ChannelBundleId = InjectedValues[\.sharedAppState].selectedChannelBundleId
    
    //MARK: - Private API - Actions and action view modifiers
    
    @objc private func viewTapped(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
            case .began:
                onTapDownFocusEffect()

            case .ended, .changed, .cancelled, .failed:
                onTapUpFocusEffect()

                if gesture.state == .ended, let channel {
                    swiftDataController.toggleIsFavorite(channelId: channel.id,
                                                         channelBundleId: channelBundleId)
                    //Got to notify VC so the rows can be refreshed.
                    self.delegate?.toggleFavoriteChannel(channel.id)
                }
                
            default:
                break
        }
    }
    
    @objc private func viewLeftSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard gesture.state == .ended else { return }
        logDebug("Left swipe detected on Siri remote")
        
    }
    
    //MARK: - Private API

    private var channel: Channel?
    
    @Injected(\.swiftDataController)
    private var swiftDataController: SwiftDataProvider
    
    private func updateLoadingState(isLoading: Bool) {
        if isLoading {
            longTapGesture.isEnabled = false
        } else {
            longTapGesture.isEnabled = true
        }
    }

    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?

    func configure(with channel: Channel?, isPlaying: Bool) {
        self.channel = channel
        let isFavorite: Bool = swiftDataController.isFavorite(channelId: channel?.id,
                                                              channelBundleId: channelBundleId)
        
        backgroundColor = (isPlaying) ? .guideSelectedChannelBackground : .guideBackgroundNoFocus

        if (channel == nil) {
            imageView.layer.opacity = 0.0
        } else {
            imageView.layer.opacity = 1.0
            imageView.tintColor = (isFavorite) ? .systemYellow : .white
        }
        
        let imageName = isFavorite ? "star.fill" : "star"
        imageView.image = UIImage(systemName: imageName)?.withRenderingMode(.alwaysTemplate)
    }
}

//MARK: - tvOS Focus overrides

extension FavoriteToggleView: @MainActor FocusTargetView {
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if (context.nextFocusedView === self) {
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
        }
    }
}


#Preview {
    // Override the injected AppStateProvider
    let appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channel1 = try! swiftDataController.channel(for: swiftDataController.channelBundleMap.channelIds[2])
    
    let view = FavoriteToggleView()
    
    let heightConstraint = view.heightAnchor.constraint(equalToConstant: AppStyle.rowHeight)
    heightConstraint.priority = UILayoutPriority(999)
    heightConstraint.isActive = true
    
    view.configure(with: channel1, isPlaying: false)
    
    return view
}
