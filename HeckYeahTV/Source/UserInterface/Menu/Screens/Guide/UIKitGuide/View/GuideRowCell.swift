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
        logDebug("Preparing for reuse")
        channelId = nil
        programs = nil
        programsCollectionView.reloadData()
        channelNameView.configure(with: nil, isPlaying: isPlaying)
        favoriteButtonView.configure(with: nil, isPlaying: isPlaying)
        updateProgramsDisplay(with: nil, isPlaying: isPlaying)
    }
    
    private func commonInit() {
        let widthConstraint = self.widthAnchor.constraint(equalToConstant: 9999)
        widthConstraint.priority = UILayoutPriority(999)
        widthConstraint.isActive = true

        backgroundColor = .clear
        selectionStyle = .none
        clipsToBounds = false
        layer.masksToBounds = false
        addRowStackView()
        channelNameView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.26).isActive = true
        bindViewModel()
    }
    
    //MARK: - static internal API
    
    static var identifier: String = "GuideRowCellIdentifier"
    static var viewCornerRadius: CGFloat = AppStyle.cornerRadius
    
    //MARK: - Private API
    
    private var isPlaying: Bool = false
    private(set) var channelId: ChannelId?
    private var channel: Channel?
    private var programs: [ChannelProgram]?
    private var currentTime: Date = Date()
    private var channelLoader = ChannelRowLoader()
    private var programsLoader = ProgramsRowLoader()
    private var cancellableStore = Set<AnyCancellable>()
    
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
            .store(in: &cancellableStore)
        
        programsLoader.$programs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] programs in
                guard let self, channelId == channel?.id else { return }
                self.programs = programs
                self.currentTime = Date() // Update the time once when programs are loaded
                self.updateProgramsDisplay(with: channelId, isPlaying: isPlaying)
            }
            .store(in: &cancellableStore)
    }
        
    //MARK: - Private API - Lazy view binding
    
    private func addRowStackView() {
        contentView.configureChildView(rowStackView)
        programsCollectionView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        programsCollectionView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    private(set) lazy var channelNameView: ChannelNameView = ChannelNameView()
    
    private lazy var favoriteButtonView: FavoriteToggleView = FavoriteToggleView()

    private lazy var emptyProgramView: EmptyProgramView = {
        let _emptyProgramView = EmptyProgramView(frame: CGRect.zero)
        programsMaskView.configureChildView(_emptyProgramView, withInset: UIEdgeInsets(top: 0,
                                                                                       left: 10,
                                                                                       bottom: 0,
                                                                                       right: AppStyle.GuideView.programSpacing))
        _emptyProgramView.isHidden = true
        return _emptyProgramView
    }()
        
    private lazy var rowStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = AppStyle.GuideView.programSpacing
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.addArrangedSubview(favoriteButtonView)
        stackView.addArrangedSubview(channelNameView)
        stackView.addArrangedSubview(programsMaskView)
        return stackView
    }()
    
    private lazy var programsMaskView: HorizontalClipContainer = {
        let view = HorizontalClipContainer(leftClip: 0, rightClip: AppStyle.GuideView.programSpacing)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.configureChildView(programsCollectionView)
        return view
    }()
  
    private lazy var programsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = AppStyle.GuideView.programSpacing
        layout.estimatedItemSize = .zero // Important: Disable self-sizing to use delegate sizes
        
        let _collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        _collectionView.translatesAutoresizingMaskIntoConstraints = false
        _collectionView.dataSource = self
        _collectionView.delegate = self
        _collectionView.showsHorizontalScrollIndicator = true
        _collectionView.showsVerticalScrollIndicator = false
        _collectionView.backgroundColor = .clear
        _collectionView.clipsToBounds = false
        _collectionView.register(ProgramCollectionViewCell.self,
                                 forCellWithReuseIdentifier: ProgramCollectionViewCell.cellIdentifier)
        
        _collectionView.contentInset = .init(top: 0,
                                             left: 10,
                                             bottom: 0,
                                             right: AppStyle.GuideView.programSpacing)
        
        return _collectionView
    }()
    
    //MARK: - Private API
    
    private func updateProgramsDisplay(with channelId: ChannelId?, isPlaying: Bool) {
        guard let programs, programs.isEmpty == false else {
            emptyProgramView.isHidden = false
            emptyProgramView.configure(isPlaying: isPlaying, isLoading: (channelId == nil))
            return
        }

        emptyProgramView.isHidden = true
        programsCollectionView.reloadData()
        scrollToCurrentProgram()
    }
    
    private func scrollToCurrentProgram() {
        guard let programs else { return }
        
        // Find the index of the currently playing program
        let currentProgramIndex = programs.firstIndex { program in
            program.startTime <= currentTime && program.endTime >= currentTime
        }
        guard let index = currentProgramIndex else { return }
        let indexPath = IndexPath(item: index, section: 0)
        programsCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }
    
    private func viewForChannelProgramId(_ id: ChannelProgramId?) -> ProgramCollectionViewCell? {
        guard let id else { return nil }
        let cell = programsCollectionView.visibleCells.first(where: {
            ($0 as? ProgramCollectionViewCell)?.channelProgramId == id
        }) as? ProgramCollectionViewCell
        return cell
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
                   isPlaying: Bool) {
        
        self.channelId = channelId
        self.isPlaying = isPlaying
        
        if self.channel?.id != channelId {
            channelLoader.load(channelId: channelId)
            programsLoader.load(channelId: channelId)
        }

        channelNameView.configure(with: self.channel, isPlaying: isPlaying)
        favoriteButtonView.configure(with: self.channel, isPlaying: isPlaying)
        updateProgramsDisplay(with: self.channel?.id, isPlaying: isPlaying)
    }
}

//MARK: - tvOS UIFocusEnvironment, FocusTargetView implementation

extension GuideRowCell {

    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
        var environments: [UIFocusEnvironment] = [UIFocusEnvironment]()
        environments.append(self.channelNameView)
        environments.append(self.favoriteButtonView)
        environments.append(self.programsCollectionView)
        return environments
    }
    
    override var canBecomeFocused: Bool {
        return false
    }
}

//MARK: - UICollectionViewDataSource protocol

extension GuideRowCell: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.programs?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProgramCollectionViewCell.cellIdentifier,
                                                      for: indexPath) as! ProgramCollectionViewCell

        let program = self.programs?[indexPath.item]
        cell.programView.configure(with: program, isPlaying: isPlaying)
        cell.channelProgramId = program?.id
        
        var isProgramNow: Bool = false
        if let _program = program {
            isProgramNow = _program.startTime <= currentTime && _program.endTime >= currentTime
        }
        
        let backgroundColor = AppStyle.GuideView.backgroundColor(isFocused: false,
                                                                 isPlaying: isPlaying,
                                                                 isProgramNow: isProgramNow)

        cell.backgroundColor = UIColor(backgroundColor)
        
        return cell
    }
}

//MARK: - UICollectionViewDelegate protocol

extension GuideRowCell: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let channelProgram = self.programs?[indexPath.item]
        guard let channelProgram else { return }
        let view = self.viewForChannelProgramId(channelProgram.id)
        self.delegate?.updateTargetFocusView(view)
        self.delegate?.showChannelProgram(channelProgram)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, 
                                   withVelocity velocity: CGPoint, 
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        guard let collectionView = scrollView as? UICollectionView,
              let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        // Calculate the cell width including spacing
        let cellWidth = AppStyle.ProgramView.width
        let spacing = layout.minimumLineSpacing
        let cellWidthWithSpacing = cellWidth + spacing
        
        // Account for content inset
        let contentOffsetX = targetContentOffset.pointee.x + collectionView.contentInset.left
        
        // Calculate which cell to snap to
        let targetIndex: CGFloat
        if velocity.x > 0 {
            // Scrolling right, snap to next cell
            targetIndex = ceil(contentOffsetX / cellWidthWithSpacing)
        } else if velocity.x < 0 {
            // Scrolling left, snap to previous cell
            targetIndex = floor(contentOffsetX / cellWidthWithSpacing)
        } else {
            // No velocity, snap to nearest cell
            targetIndex = round(contentOffsetX / cellWidthWithSpacing)
        }
        
        // Calculate the new offset
        let newOffset = (targetIndex * cellWidthWithSpacing) - collectionView.contentInset.left
        targetContentOffset.pointee.x = newOffset
    }
}

//MARK: - UICollectionViewDelegateFlowLayout protocol

extension GuideRowCell: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {

        let height = collectionView.bounds.height
        let width: CGFloat = AppStyle.ProgramView.width
        
        return CGSize(width: width, height: height)
    }
}





//MARK: - Preview Code

#Preview("UIKit Preview") {
    // Override the injected AppStateProvider
    let appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channel1 = try! swiftDataController.channel(for: swiftDataController.channelBundleMap.channelIds[11])
    
    let view = GuideRowCell()
    view.configure(with: channel1.id,
                   isPlaying: false)
    
    let heightConstraint = view.heightAnchor.constraint(equalToConstant: AppStyle.rowHeight)
    heightConstraint.priority = UILayoutPriority(1000)
    heightConstraint.isActive = true
    
    let widthConstraint = view.widthAnchor.constraint(equalToConstant: 9999)
    widthConstraint.priority = UILayoutPriority(999)
    widthConstraint.isActive = true
    
    return view
}
