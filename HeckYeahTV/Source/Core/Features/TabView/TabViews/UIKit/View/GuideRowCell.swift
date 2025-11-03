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
import Combine
import SwiftData

class GuideRowCell: PlatformTableViewCell {
    
    //MARK: - PlatformTableViewCell overrides
    
//    deinit  {
//        logDebug("Deallocated")
//    }
    
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
        logFatal("init?(coder:) has not been implemented.")
    }
    
#if !os(macOS)
    override func prepareForReuse() {
        super.prepareForReuse()
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        channelId = nil
        programs = []
    }
#endif
    
    private func commonInit() {
#if os(macOS)
        self.wantsLayer = true
        self.layer?.masksToBounds = false
        self.clipsToBounds = false
#else
        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        layer.masksToBounds = false
#endif
        rowStackView.spacing = 35
        programsStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        programsStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        bindViewModel()
    }
    
    //MARK: - static internal API
    
    static var identifier: String = "GuideRowCellIdentifier"
    
    //MARK: - Private API - View Models
    
    private var isPlaying: Bool = false
    private(set) var channelId: ChannelId?
    private var channel: IPTVChannel?
    private var programs: [Program] = []
    private var channelLoader = GuideRowLoader()
    private var loaderBindings = Set<AnyCancellable>()
    
    //MARK: - Binding ObservableObject to UIKit
    
    private func bindViewModel() {
        channelLoader.$channel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] channel in
                guard let self, channelId == channel?.id else { return }
                self.channel = channel
                self.channelNameView.configure(with: channel, isPlaying: isPlaying)
                self.favoriteButtonView.configure(with: channel, isPlaying: isPlaying)
                self.updateProgramsDisplay(with: channel?.id, isPlaying: isPlaying)
            }
            .store(in: &loaderBindings)
    }
        
    //MARK: - Private API - Lazy view binding
    
    private(set) lazy var channelNameView: ChannelNameView = {
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
        view.alignment = .width
#else
        contentView.addSubview(view)
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
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
        view.clipsToBounds = false
#if os(macOS)
        view.wantsLayer = true
        view.layer?.masksToBounds = false
        view.layer?.backgroundColor = .clear
        view.alignment = .width
#else
        view.layer.masksToBounds = false
        view.backgroundColor = .clear
        view.alignment = .fill
#endif
        return view
    }()
    
    //MARK: - Private API
    
    private func updateProgramsDisplay(with channelId: ChannelId?, isPlaying: Bool) {
        // Clear existing program views
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        programsMaskView.viewWithTag(EmptyProgramView.viewTypeTagId)?.removeFromSuperview()
        
        if channelId == nil || programs.count == 0 {
            let emptyProgramView = EmptyProgramView(frame: CGRect.zero)
            emptyProgramView.configure(isPlaying: isPlaying, isLoading: (channelId == nil))
            programsMaskView.addSubview(emptyProgramView)
            emptyProgramView.fillSuperview()
        } else {
            // Add new program views
            for program in programs {
                let programView = ProgramView()
                programView.delegate = self.delegate
                programView.configure(with: program, channelId: channelId, isPlaying: isPlaying)
                programsStackView.addArrangedSubview(programView)
            }
        }
    }
    
    //MARK: - Internal API

    weak var delegate: GuideViewDelegate? {
        didSet {
            self.channelNameView.delegate = self.delegate
            self.favoriteButtonView.delegate = self.delegate
        }
    }

    @MainActor
    func configure(with channelId: ChannelId, isPlaying: Bool, programs: [Program], viewContext: ModelContext) {
        self.channelId = channelId
        self.programs = programs
        self.isPlaying = isPlaying
        
        if self.channel?.id != channelId {
            channelLoader.load(channelId: channelId, context: viewContext)
            channelNameView.configure(with: nil, isPlaying: isPlaying)
            favoriteButtonView.configure(with: nil, isPlaying: isPlaying)
            updateProgramsDisplay(with: nil, isPlaying: isPlaying)
        } else {
            channelNameView.configure(with: self.channel, isPlaying: isPlaying)
            favoriteButtonView.configure(with: self.channel, isPlaying: isPlaying)
            updateProgramsDisplay(with: channelId, isPlaying: isPlaying)
        }
    }
}

#if os(tvOS)
//MARK: - tvOS Focus Code
extension GuideRowCell {
    
    override var canBecomeFocused: Bool {
        return false
    }
    
//    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
//        return [self.channelNameView, self.favoriteButtonView]
//    }
}
#endif
