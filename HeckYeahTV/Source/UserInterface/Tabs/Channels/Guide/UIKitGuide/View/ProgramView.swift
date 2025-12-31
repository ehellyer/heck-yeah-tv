//
//  ProgramView.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

class ProgramView: UIView {
    
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
        
        // Bootstrap the lazy loading.
        stackContainerView.backgroundColor = .clear
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(titleLabel)
        self.addGestureRecognizer(longTapGesture)
        self.widthAnchor.constraint(equalToConstant: AppStyle.ProgramView.width).isActive = true
    }
    
    required init?(coder: NSCoder) {
        logFatal("init(coder:) has not been implemented")
    }
    
    
    //MARK: - Private API - View lazy binding.
    
    private lazy var stackContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20).isActive = true
        trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor, constant: 20).isActive = true
        bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20).isActive = true
        return view
    }()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackContainerView.addSubview(stackView)
        stackView.leadingAnchor.constraint(equalTo: stackContainerView.leadingAnchor, constant: 0).isActive = true
        stackContainerView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 0).isActive = true
        stackView.topAnchor.constraint(equalTo: stackContainerView.topAnchor, constant: 0).isActive = true
        stackContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: stackView.bottomAnchor, constant: 0).isActive = true
        return stackView
    }()
    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 1
        label.font = AppStyle.Fonts.programTimeSlotFont
        label.textColor = .guideForegroundNoFocus
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 3
        label.font = AppStyle.Fonts.programTitleFont
        label.textColor = .guideForegroundNoFocus
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(UILayoutPriority(999), for: .horizontal)
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
    
    private var channelId: ChannelId?
    private var program: ChannelProgram?
    
    /// Shared date formatter for time slot strings. Reused to avoid repeated alloc/init.
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    private func formattedTimeSlot(for program: ChannelProgram) -> String {
        let startTimeString = Self.timeFormatter.string(from: program.startTime)
        let endTimeString = Self.timeFormatter.string(from: program.endTime)
        return "\(startTimeString) - \(endTimeString)"
    }
    
    private func updateViewTintColor(_ color: UIColor) {
        titleLabel.textColor = color
        timeLabel.textColor = color
    }
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewDelegate?
    
    func configure(with program: ChannelProgram?,
                   channelId: ChannelId?,
                   isPlaying: Bool) {
        self.channelId = channelId
        self.program = program
        backgroundColor = (isPlaying) ? .guideSelectedChannelBackground : .guideBackgroundNoFocus
        titleLabel.text = program?.title
        timeLabel.text = program.map { formattedTimeSlot(for: $0) } //Map used to unwrap optional.
    }
}

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
