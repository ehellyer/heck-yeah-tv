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
        
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        layer.masksToBounds = true
        layer.cornerRadius = GuideRowCell.viewCornerRadius
        isUserInteractionEnabled = true
        clipsToBounds = true
        
        // Bootstrap the lazy loading.
        stackContainerView.backgroundColor = .clear
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(titleLabel)
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
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }()
    
    //MARK: - Internal API
    
    func updateViewTintColor(_ color: UIColor) {
        titleLabel.textColor = color
        timeLabel.textColor = color
    }
    
    func configure(with program: ChannelProgram?,
                   isPlaying: Bool) {
        titleLabel.text = program?.title
        timeLabel.text = program?.formattedTimeSlot
        self.layoutIfNeeded()
    }
}

#Preview("UIKit Preview") {

    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()

    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channel = swiftDataController.previewOnly_fetchChannel(at: 1)
    let channelPrograms: [ChannelProgram] = swiftDataController.channelPrograms(for: channel.id)
    
    let view = ProgramView()
    view.configure(with: channelPrograms.first!, isPlaying: false)
    
    let heightConstraint = view.heightAnchor.constraint(equalToConstant: AppStyle.rowHeight)
    heightConstraint.priority = UILayoutPriority(1000)
    heightConstraint.isActive = true
        
    return view
}
