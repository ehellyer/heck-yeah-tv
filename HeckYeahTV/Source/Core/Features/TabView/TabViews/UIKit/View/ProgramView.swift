//
//  ProgramView.swift
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
#if !os(macOS)
        view.distribution = .fill
        view.alignment = .fill
#endif
        view.spacing = 2
        return view
    }()
    private lazy var titleLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.lineLimit = 3
#if !os(macOS)
        label.font = .systemFont(ofSize: 23, weight: .medium)
        label.textColor = .label
#endif
        return label
    }()
    private lazy var timeLabel: CrossPlatformLabel = {
        let label = PlatformUtils.createLabel()
#if os(macOS)
        // Match semantics; NSColor.labelColor equivalents
        label.font = .systemFont(ofSize: 24, weight: .semibold)
#else
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = .secondaryLabel
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 1
#endif
        return label
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
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?
    
    func configure(with program: Program?, channelId: ChannelId?, isPlaying: Bool) {
        self.channelId = channelId
        self.program = program
        bgColor = (isPlaying) ? PlatformColor(named: "selectedChannel") : PlatformColor(named: "guideBackgroundNoFocus")
        titleLabel.textValue = program?.title
        timeLabel.textValue = program?.timeSlot
    }
}

#if os(tvOS)
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
//            if let channelId {
//                delegate?.didBecomeFocused(target: FocusTarget.guide(channelId: channelId, col: 3))
//            }
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
        }
    }
}
#endif
