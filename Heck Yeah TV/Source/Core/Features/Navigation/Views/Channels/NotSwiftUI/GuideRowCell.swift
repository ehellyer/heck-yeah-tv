//
//  GuideRowCell.swift
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

class GuideRowCell: PlatformTableViewCell {
    
    //MARK: - UITableViewCell overrides
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        layer.masksToBounds = false
        rowStackView.spacing = 35
        programsStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        programsStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        channel = nil
        programs = []
    }
    
#if os(tvOS)
    // Make the cell itself not focusable; subviews will receive focus.
    override var canBecomeFocused: Bool { false }
#endif
    
    //MARK: - static internal API
    
    static var identifier: String = "GuideRowCellIdentifier"
    
    //MARK: - Private API - ViewModel, data source, props, whatever you want to call them today.
    
    private var channel: GuideChannel?
    private var programs: [Program] = []
    
    //MARK: - Private API - Lazy view binding
    
    private lazy var channelNameView: ChannelNameView = {
        let view =  ChannelNameView()
        return view
    }()
    
    private lazy var favoriteButtonView: FavoritesToggleView = {
        let view = FavoritesToggleView()
        return view
    }()

    private lazy var rowStackView: PlatformStackView = {
        let view = PlatformUtils.createStackView(axis: .horizontal)
        contentView.addSubview(view)
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        view.alignment = .fill
        view.distribution = .fill
        view.addArrangedSubview(favoriteButtonView)
        view.addArrangedSubview(channelNameView)
        view.addArrangedSubview(programsMaskView)
        return view
    }()
    private lazy var programsMaskView: HorizontalClipContainer = {
        let view = HorizontalClipContainer()
        view.leftClip = 10
        view.rightClip = 35
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(programsScrollView)
        view.leadingAnchor.constraint(equalTo: programsScrollView.leadingAnchor, constant: -10).isActive = true
        programsScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: programsScrollView.topAnchor).isActive = true
        programsScrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        programsScrollView.contentInset = .init(top: 0, left: view.leftClip, bottom: 0, right: view.rightClip)
        return view
    }()
    private lazy var programsScrollView: PlatformScrollView = {
        let view = PlatformUtils.createScrollView()
        view.addSubview(programsStackView)
        view.leadingAnchor.constraint(equalTo: programsStackView.leadingAnchor).isActive = true
        programsStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: programsStackView.topAnchor).isActive = true
        programsStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        view.clipsToBounds = false
        view.layer.masksToBounds = false
        return view
    }()
    private lazy var programsStackView: PlatformStackView = {
        let view = PlatformUtils.createStackView(axis: .horizontal)
        view.spacing = 25
        view.backgroundColor = .clear
        view.distribution = .fill
        view.alignment = .fill
        view.clipsToBounds = false
        view.layer.masksToBounds = false
//        view.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
//        view.isLayoutMarginsRelativeArrangement = true
        return view
    }()
    
    //MARK: - Private API
    
    private func updateProgramsDisplay(with channel: GuideChannel, isSelectedChannel: Bool) {
        // Clear existing program views
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new program views
        for program in programs {
            let programView = ProgramView()
            programView.delegate = self.delegate
            programView.configure(with: program, channel: channel, isSelectedChannel: isSelectedChannel)
            programsStackView.addArrangedSubview(programView)
        }
    }
    
    //MARK: - Internal API

    weak var delegate: GuideViewDelegate? {
        didSet {
            self.channelNameView.delegate = self.delegate
            self.favoriteButtonView.delegate = self.delegate
        }
    }

    func configure(with channel: GuideChannel, programs: [Program], isSelectedChannel: Bool) {
        self.channel = channel
        self.programs = programs
        
        channelNameView.configure(with: channel, isSelectedChannel: isSelectedChannel)
        favoriteButtonView.configure(with: channel, isSelectedChannel: isSelectedChannel)
        updateProgramsDisplay(with: channel, isSelectedChannel: isSelectedChannel)
    }
}
