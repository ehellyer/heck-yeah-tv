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

class ProgramView: PlatformView, FocusTargetView {
    
    //MARK: - PlatformView Overrides
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 25
        layer.masksToBounds = true
        isUserInteractionEnabled = true
        clipsToBounds = true
        
        // Bootstrap the lazy loading.
        stackContainerView.backgroundColor = .clear
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(titleLabel)
        self.addGestureRecognizer(longTapGesture)
        self.widthAnchor.constraint(equalToConstant: 260).isActive = true
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
                delegate?.didBecomeFocused(target: FocusTarget.guide(channelId: channel.id, col: 3))
            }
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator)
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator)
            if let channel {
                delegate?.didLoseFocus(target: FocusTarget.guide(channelId: channel.id, col: 3))
            }
        }
    }

    //MARK: - Private API - View lazy binding.
    
    private lazy var stackContainerView: PlatformView = {
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
    private lazy var titleLabel: PlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 23, weight: .medium)
        label.numberOfLines = 3
        label.textColor = .label
        return label
    }()
    private lazy var timeLabel: PlatformLabel = {
        let label = PlatformUtils.createLabel()
        label.font = .systemFont(ofSize: 24, weight: .semibold)
        label.textColor = .secondaryLabel
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 1
        return label
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
                if gesture.state == .ended {
                    //TODO: Not yet implemented.  Put code here to send a message to the delegate to present information about the program.
                }
                
            default:
                break
        }
    }
    
    //MARK: - Private API

    private var channel: GuideChannel?
    private var isSelectedChannel: Bool = false
    private var program: Program?
    
    //MARK: - Internal API
    
    weak var delegate: GuideFocusViewDelegate?
    
    func refreshView() {
        backgroundColor = (isSelectedChannel) ? PlatformColor(named: "selectedChannelColor") : PlatformColor(named: "guideBackgroundNoFocusColor")
        guard let program = program else { return }
        titleLabel.text = program.title
        timeLabel.text = program.timeSlot
    }
    
    func configure(with program: Program?, channel: GuideChannel, isSelectedChannel: Bool) {
        self.channel = channel
        self.isSelectedChannel = isSelectedChannel
        self.program = program
        refreshView()
    }
}
