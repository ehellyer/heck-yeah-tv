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
    
    //MARK: - PlatformTableViewCell overrides
    
#if os(macOS)
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
#else
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
#endif
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
#if !os(macOS)
    override func prepareForReuse() {
        super.prepareForReuse()
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        channel = nil
        programs = []
    }
#endif
    
#if os(tvOS)
    // Make the cell itself not focusable; subviews will receive focus.
    override var canBecomeFocused: Bool { false }
#endif
    
    private func commonInit() {
#if os(macOS)
        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.clipsToBounds = false
        // On macOS, NSTableCellView doesn't have contentView; use self as container.
        rowStackView.spacing = 35
        programsStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        programsStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
#else
        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        layer.masksToBounds = false
        rowStackView.spacing = 35
        programsStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        programsStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
#endif
    }
    
    //MARK: - static internal API
    
    static var identifier: String = "GuideRowCellIdentifier"
    
    //MARK: - Private API - View Models
    
    private var channel: IPTVChannel?
    private var programs: [Program] = []
    
    //MARK: - Private API - Lazy view binding
    
    private lazy var channelNameView: ChannelNameView = {
        let view =  ChannelNameView()
        return view
    }()
    
    private lazy var favoriteButtonView: FavoriteToggleView = {
        let view = FavoriteToggleView()
        return view
    }()

    private lazy var rowStackView: PlatformStackView = {
        let view = PlatformUtils.createStackView(axis: .horizontal)
#if os(macOS)
        self.addSubview(view)
        view.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
#else
        contentView.addSubview(view)
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
#endif
#if os(macOS)
        view.alignment = .width
#else
        view.alignment = .fill
#endif

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
#if os(macOS)
        programsScrollView.contentInset = NSEdgeInsetsCompat(top: 0, left: view.leftClip, bottom: 0, right: view.rightClip)
#else
        programsScrollView.contentInset = .init(top: 0, left: view.leftClip, bottom: 0, right: view.rightClip)
#endif
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
#if os(macOS)
        view.wantsLayer = true
        view.layer?.masksToBounds = false
#else
        view.layer.masksToBounds = false
#endif
        return view
    }()
    private lazy var programsStackView: PlatformStackView = {
        let view = PlatformUtils.createStackView(axis: .horizontal)
        view.spacing = 25
        
        view.distribution = .fill
#if os(macOS)
        view.alignment = .width
#else
        view.alignment = .fill
#endif
        view.clipsToBounds = false
#if os(macOS)
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        view.layer?.backgroundColor = .clear
#else
        view.layer.masksToBounds = false
        view.backgroundColor = .clear
#endif
        return view
    }()
    
    //MARK: - Private API
    
    private func updateProgramsDisplay(with channel: IPTVChannel) {
        // Clear existing program views
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new program views
        for program in programs {
            let programView = ProgramView()
            programView.delegate = self.delegate
            programView.configure(with: program, channel: channel)
            programsStackView.addArrangedSubview(programView)
        }
    }
    
#if os(tvOS)
    /// Resolve a FocusTarget for this row into a concrete UIView that can become focused.
    /// Convention: col 0 = FavoriteToggleView, col 1 = ChannelNameView, col >= 2 = ProgramView at index (col - 2)
    func focusableView(for target: FocusTarget) -> UIView? {
        guard case let .guide(channelId, col) = target,
              let channel,
              channel.id == channelId else {
            return nil
        }
        if col == 0 { return favoriteButtonView }
        if col == 1 { return channelNameView }
        let programIndex = col - 2
        guard programIndex >= 0, programIndex < programsStackView.arrangedSubviews.count else {
            return nil
        }
        return programsStackView.arrangedSubviews[programIndex]
    }
#endif
    
    //MARK: - Internal API

    weak var delegate: GuideViewDelegate? {
        didSet {
            self.channelNameView.delegate = self.delegate
            self.favoriteButtonView.delegate = self.delegate
        }
    }

    func configure(with channel: IPTVChannel, programs: [Program]) {
        self.channel = channel
        self.programs = programs
        
        channelNameView.configure(with: channel)
        favoriteButtonView.configure(with: channel)
        updateProgramsDisplay(with: channel)
    }
}

