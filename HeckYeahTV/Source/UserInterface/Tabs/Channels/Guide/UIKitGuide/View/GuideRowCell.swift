//
//  GuideRowCell.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit
import Combine
import SwiftData

class GuideRowCell: UITableViewCell {
    
    //MARK: - UITableViewCell overrides
    
//    deinit  {
//        logDebug("Deallocated")
//    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        logFatal("init?(coder:) has not been implemented.")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        channelId = nil
        programs = nil
    }
    
    private func commonInit() {
        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        layer.masksToBounds = false
        addRowStackView()
        channelNameView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.3).isActive = true
        bindViewModel()
    }
    
    //MARK: - static internal API
    
    static var identifier: String = "GuideRowCellIdentifier"
    static var viewCornerRadius: CGFloat = 25.0
    
    //MARK: - Private API - View Models
    
    private var isPlaying: Bool = false
    private(set) var channelId: ChannelId?
    private var channel: Channel?
    private var programs: [ChannelProgram]?
    private var channelLoader = ChannelRowLoader()
    private var programsLoader = ProgramsRowLoader()
    private var channelLoaderBindings = Set<AnyCancellable>()
    private var programsLoaderBindings = Set<AnyCancellable>()
    
    //MARK: - Binding ObservableObject to UIKit
    
    private func bindViewModel() {
        channelLoader.$channel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] channel in
                guard let self, channelId == channel?.id else { return }
                self.channel = channel
                self.channelNameView.configure(with: channel, isPlaying: isPlaying)
                self.favoriteButtonView.configure(with: channel, isPlaying: isPlaying)
            }
            .store(in: &channelLoaderBindings)
        
        programsLoader.$programs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] programs in
                guard let self, channelId == programs?.first?.channelId else { return }
                self.programs = programs
                self.updateProgramsDisplay(with: channel?.id, isPlaying: isPlaying)
            }
            .store(in: &channelLoaderBindings)
    }
        
    //MARK: - Private API - Lazy view binding
    
    private func addRowStackView() {
        contentView.addSubview(rowStackView)
        rowStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: rowStackView.trailingAnchor).isActive = true
        rowStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: rowStackView.bottomAnchor).isActive = true
        //
        programsStackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        programsStackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    private(set) lazy var channelNameView: ChannelNameView = {
        let view =  ChannelNameView()
        return view
    }()
    
    private lazy var favoriteButtonView: FavoriteToggleView = {
        let view = FavoriteToggleView()
        return view
    }()

    private lazy var rowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 35
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.addArrangedSubview(favoriteButtonView)
        stackView.addArrangedSubview(channelNameView)
        stackView.addArrangedSubview(programsMaskView)
        return stackView
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
    
    private lazy var programsScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.addSubview(programsStackView)
        scrollView.leadingAnchor.constraint(equalTo: programsStackView.leadingAnchor).isActive = true
        programsStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: programsStackView.topAnchor).isActive = true
        programsStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        scrollView.clipsToBounds = false
        scrollView.layer.masksToBounds = false
        return scrollView
    }()
    
    private lazy var programsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 25
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.clipsToBounds = false
        stackView.layer.masksToBounds = false
        stackView.backgroundColor = .clear
        return stackView
    }()
    
    //MARK: - Private API
    
    private func updateProgramsDisplay(with channelId: ChannelId?, isPlaying: Bool) {
        // Clear existing program views
        programsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        programsMaskView.viewWithTag(EmptyProgramView.viewTypeTagId)?.removeFromSuperview()
        
        guard let programs, programs.count > 0 else {
            // Add 'No guide information' view.
            let emptyProgramView = EmptyProgramView(frame: CGRect.zero)
            emptyProgramView.configure(isPlaying: isPlaying, isLoading: (channelId == nil))
            programsMaskView.addSubview(emptyProgramView)
            emptyProgramView.fillSuperview()
            return
        }
        
        // Add program views
        for program in programs {
            let programView = ProgramView()
            programView.delegate = self.delegate
            programView.configure(with: program, channelId: channelId, isPlaying: isPlaying)
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

    @MainActor
    func configure(with channelId: ChannelId,
                   isPlaying: Bool,
                   viewContext: ModelContext) {
        self.channelId = channelId
        self.isPlaying = isPlaying
        
        if self.channel?.id != channelId {
            channelLoader.load(channelId: channelId, context: viewContext)
            programsLoader.load(channelId: channelId, context: viewContext)
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

//MARK: - tvOS Focus Code

extension GuideRowCell {
    
    override var canBecomeFocused: Bool {
        return false
    }
    
    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
        return [self.channelNameView, self.favoriteButtonView]
    }
}
