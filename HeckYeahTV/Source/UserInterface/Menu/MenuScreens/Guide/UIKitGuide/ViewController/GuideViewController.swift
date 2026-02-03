//
//  GuideViewController.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/18/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit
import SwiftData
import Observation
import SwiftUI

class GuideViewController: UIViewController {

    //MARK: - UIViewController overrides
    
    deinit {
        logDebug("Deallocated GuideViewController at \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        logDebug("Init GuideViewController at \(Unmanaged.passUnretained(self).toOpaque())")
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        logDebug("Init GuideViewController at \(Unmanaged.passUnretained(self).toOpaque())")
        commonInit()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupSwiftDataObservation()
        updateShowNoChannels()
        try? swiftDataController.deletePastChannelPrograms()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToSelectedChannel(animated: false)
        
        DispatchQueue.main.async { [weak self] in
            self?.applySelectedChannelFocus()
        }
        
        // Observe carousel dismissal to restore focus
        setupCarouselObservation()
    }

    //MARK: - Private API - Lazy binding vars
    
    private weak var targetFocusView: UIView?
    
    private lazy var tableView: UITableView = {
        let _tableView = UITableView()
        _tableView.translatesAutoresizingMaskIntoConstraints = false
        _tableView.dataSource = self
        _tableView.clipsToBounds = true
        _tableView.allowsSelection = false
        _tableView.estimatedRowHeight = 120
        _tableView.sectionHeaderTopPadding = 0.0
        _tableView.rowHeight = UITableView.automaticDimension
        _tableView.sectionHeaderHeight = 0.0
        _tableView.estimatedSectionHeaderHeight = 0.0

        view.addSubview(_tableView)

        _tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: _tableView.trailingAnchor).isActive = true
        _tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: _tableView.bottomAnchor).isActive = true
        
        return _tableView
    }()
    
    private lazy var noChannelsHostingController: UIHostingController<NoChannelsInChannelBundle> = {
        let noChannelsView = NoChannelsInChannelBundle()
        let _hostingVC = UIHostingController(rootView: noChannelsView)
        _hostingVC.view.translatesAutoresizingMaskIntoConstraints = false
        return _hostingVC
    }()

    private func updateShowNoChannels() {
        if self.swiftDataController.channelBundleMap.map.isEmpty {
            self.showNoChannelsView()
        } else {
            self.hideNoChannelsView()
        }
    }
    
    private func showNoChannelsView() {
        guard noChannelsHostingController.parent == nil else {
            return
        }
        addChild(noChannelsHostingController)
        view.addSubview(noChannelsHostingController.view)
        noChannelsHostingController.didMove(toParent: self)
        noChannelsHostingController.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        noChannelsHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        noChannelsHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        noChannelsHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    private func hideNoChannelsView() {
        guard noChannelsHostingController.parent != nil else {
            return
        }
        noChannelsHostingController.willMove(toParent: nil)
        noChannelsHostingController.view.removeFromSuperview()
        noChannelsHostingController.removeFromParent()
    }
    
    //MARK: - Private API
    
    @Injected(\.swiftDataController)
    private var swiftDataController: SwiftDataProvider
    
    @Injected(\.sharedAppState)
    private var appState: AppStateProvider
    
    private var reloadTableViewTask: Task<Void, Never>? = nil
    
    private var targetChannelId: ChannelId? {
        return appState.selectedChannel ?? swiftDataController.channelBundleMap.map.first?.channelId
    }
    
    private func setupTableView() {
        tableView.register(GuideRowCell.self, forCellReuseIdentifier: GuideRowCell.identifier)
    }
    
    private func commonInit() {
        restoresFocusAfterTransition = false
    }
    
    //MARK: - Observation of SwiftDataProvider
    
    private func setupSwiftDataObservation() {
        
        withObservationTracking({
            // Access the property we care about. This registers the dependency.
            _ = swiftDataController.channelBundleMap.map
        }, onChange: { [weak self] in
            // Called when any accessed observed property in the tracking block changes.
            Task { @MainActor [weak self] in
                self?.reloadTableViewTask?.cancel()
                self?.reloadTableViewTask = Task { @MainActor [weak self] in
                    //Debounce the observation.
                    try? await Task.sleep(nanoseconds: debounceNS)
                    guard !Task.isCancelled else { return }
                    self?.tableView.reloadData()
                    self?.scrollToSelectedChannel()
                    self?.updateShowNoChannels()
                    self?.setupSwiftDataObservation()
                }
            }
        })
    }
    
    private func setupCarouselObservation() {
        withObservationTracking({
            _ = appState.showProgramDetailCarousel
        }, onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                if self.appState.showProgramDetailCarousel == nil, let view = self.targetFocusView {
                    self.requestFocus(on: view)
                }

                self.setupCarouselObservation()
            }
        })
    }

    private func setPlayingChannel(id: ChannelId) throws {
        appState.selectedChannel = id
        reloadVisibleRows()
    }
    
    private func toggleFavorite(id: ChannelId) throws {
        reloadVisibleRows()
    }

    private func reloadVisibleRows() {
        let cells = self.tableView.visibleCells as? [GuideRowCell] ?? []
        let selectedChannel = appState.selectedChannel
        
        cells.forEach { cell in
            let channelId = cell.channelId ?? "666" // "666" will never be a valid channelId, but that is ok and safer than force unwrap.
            let isPlaying = selectedChannel == channelId
            cell.configure(with: channelId,
                           isPlaying: isPlaying)
        }
    }
    
    private func scrollToSelectedChannel(animated: Bool = true) {
        guard let _channelId = targetChannelId, swiftDataController.channelBundleMap.map.isEmpty == false else { return }
        let index = swiftDataController.channelBundleMap.map.firstIndex(where: { $0.channelId == _channelId }) ?? 0
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
    }
    
    //MARK: - Private API - Focus
    
    private func selectedChannelView() -> UIView? {
        let visibleCells: [GuideRowCell] = self.tableView.visibleCells as? [GuideRowCell] ?? []
        guard let channelId = targetChannelId,
              let cell = visibleCells.first(where: { $0.channelId == channelId }) else {
            logDebug("📍 Cell for targetChannelId not found in visible cells")
            return nil
        }
        return cell.channelNameView
    }
    
    private func applySelectedChannelFocus() {
        self.targetFocusView = selectedChannelView()
        if let view = self.targetFocusView {
            self.requestFocus(on: view)
        }
    }

    private func requestFocus(on view: UIView) {
        guard view.canBecomeFocused else {
            logDebug("📍 View is not focusable: \(type(of: view))")
            return
        }
        
        // Verify the view is still in the view hierarchy
        guard view.window != nil else {
            logDebug("📍 View is not in window hierarchy: \(type(of: view))")
            return
        }
        
        logDebug("📍 Requesting focus on: \(type(of: view))")
        // Set the target view FIRST so preferredFocusEnvironments returns it
        self.targetFocusView = view
        self.updateFocusIfNeeded()
        self.setNeedsFocusUpdate()
        
        // Calling a 2nd time after a delay because the Focus engine is a real pain in the ass.  Yes this is a hack to get around an Apple Framework bug.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            // Request focus update on the view controller which triggers call to preferredFocusEnvironments
            self.updateFocusIfNeeded()
            self.setNeedsFocusUpdate()
        }
    }
}

//MARK: - tvOS UIFocusEnvironment, FocusTargetView implementation

extension GuideViewController {
    
    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
        var environments: [UIFocusEnvironment] = [UIFocusEnvironment]()
        self.targetFocusView.map { environments.append($0) }
        environments.append(self.tableView)
        return environments
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return (appState.showProgramDetailCarousel == nil)
    }
}

//MARK: - GuideViewDelegate protocol

extension GuideViewController: GuideViewDelegate {
        
    func selectChannel(_ channelId: ChannelId) {
        guard channelId != appState.selectedChannel else { return }
        try? self.setPlayingChannel(id: channelId)
    }
    
    func toggleFavoriteChannel(_ channelId: ChannelId) {
        try? self.toggleFavorite(id: channelId)
    }
    
    func showChannelProgram(_ channelProgram: ChannelProgram) {
        appState.showProgramDetailCarousel = channelProgram
    }
    
    func updateTargetFocusView(_ programView: ProgramCollectionViewCell?) {
        self.targetFocusView = programView
    }
}

// MARK: - UITableViewDataSource protocol

extension GuideViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return min(swiftDataController.channelBundleMap.mapCount, 1) //Clamp to 0 or 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return swiftDataController.channelBundleMap.mapCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let guideRowCell = tableView.dequeueReusableCell(withIdentifier: GuideRowCell.identifier, for: indexPath) as! GuideRowCell
        let channelId = swiftDataController.channelBundleMap.map[indexPath.row].channelId
        let isPlaying = (channelId == appState.selectedChannel)
        guideRowCell.configure(with: channelId,
                               isPlaying: isPlaying)
        guideRowCell.delegate = self
        return guideRowCell
    }
}

#Preview {
    // Override the injected AppStateProvider
    let appState: AppStateProvider = MockSharedAppState()
    InjectedValues[\.sharedAppState] = appState
    
    // Override the injected SwiftDataController
    let swiftDataController = MockSwiftDataController()
    InjectedValues[\.swiftDataController] = swiftDataController
    
    //Test the no channels view
    //swiftDataController.channelBundleMap.update(map: [])
    
    return GuideViewController()
}
