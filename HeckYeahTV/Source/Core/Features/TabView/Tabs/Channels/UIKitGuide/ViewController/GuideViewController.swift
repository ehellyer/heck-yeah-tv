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

class GuideViewController: PlatformViewController {

    //MARK: - PlatformViewController overrides
    
    deinit {
        logDebug("Deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupAppStateObservation()
        
        // Make the view controller's view focusable so UIKit can take over focus
        self.view.isUserInteractionEnabled = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollToSelectedChannel(animated: false)
        DispatchQueue.main.async { [weak self] in
            self?.applyFocus()
        }
    }

    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
        // If we have a specific target view, prefer it
        if let targetView = self.targetFocusView {
            return [targetView]
        }
        // Otherwise prefer the table view so focus can enter our UIKit hierarchy
        return [self.tableView]
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        // Clear the target once it receives focus
        if let targetView = targetFocusView, context.nextFocusedItem as? UIView == targetView {
            targetFocusView = nil
        }
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    //MARK: - Private API - Lazy binding vars
    
    private weak var targetFocusView: PlatformView?
    
    private lazy var tableView: PlatformTableView = {
        let _tableView = PlatformUtils.createTableView()
        view.addSubview(_tableView)
        _tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: _tableView.trailingAnchor).isActive = true
        _tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: _tableView.bottomAnchor).isActive = true
        _tableView.clipsToBounds = false
        _tableView.estimatedRowHeight = 120
        if #available(iOS 15.0, tvOS 15.0, *) {
            _tableView.sectionHeaderTopPadding = 0.0
        }
        _tableView.rowHeight = UITableView.automaticDimension
        _tableView.sectionHeaderHeight = UITableView.automaticDimension
        _tableView.estimatedSectionHeaderHeight = 50
        return _tableView
    }()
    
    //MARK: - Private API
    
    typealias SectionModel = Int
    private var section: SectionModel = 0
    private lazy var viewContext = DataPersistence.shared.viewContext
    private var reloadTableViewTask: Task<Void, Never>? = nil
    
    //TODO: Integrate program data into IPTVChannel
    private var channelPrograms: [Program] = Program.mockPrograms()

    private var targetChannelId: ChannelId? {
        return appState.selectedChannel ?? channelMap.map.first
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.clipsToBounds = true
        tableView.register(GuideRowCell.self, forCellReuseIdentifier: GuideRowCell.identifier)
        tableView.allowsSelection = false
    }
    
    //MARK: - Observation of SharedAppState
    
    private func setupAppStateObservation() {
        // If appState hasn't been injected yet, nothing to observe.
        guard let channelMap else { return }
        
        withObservationTracking({
            // Access the property we care about. This registers the dependency.
            _ = channelMap.totalCount
        }, onChange: { [weak self] in
            // Called when any accessed observed property in the tracking block changes.
            Task { @MainActor [weak self] in
                self?.reloadTableViewTask?.cancel()
                self?.reloadTableViewTask = Task { @MainActor [weak self] in
                    do {
                        //Debounce the observation.
                        try await Task.sleep(nanoseconds: debounceNS)
                        try Task.checkCancellation()
                        self?.tableView.reloadData()
                        self?.scrollToSelectedChannel()
                        self?.setupAppStateObservation()
                    } catch {
                        //Do nothing, task was cancelled.
                    }
                }
            }
        })
    }

    private func setPlayingChannel(id: String) throws {
        appState?.selectedChannel = id
        reloadVisibleRows()
    }
    
    private func toggleFavorite(id: String) throws {
        let predicate = #Predicate<IPTVChannel> { $0.id == id }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let channel = try viewContext.fetch(descriptor).first {
            channel.isFavorite.toggle()
            try viewContext.save()
        }
        reloadVisibleRows()
    }

    private func reloadVisibleRows() {
        let cells = self.tableView.visibleCells as? [GuideRowCell] ?? []
        let selectedChannel = appState?.selectedChannel
        
        cells.forEach { cell in
            let channelId = cell.channelId ?? "666" // Will never be "666", but safer than force unwrap.
            let isPlaying = selectedChannel == channelId
            if isPlaying {
                self.targetFocusView = cell.channelNameView
            }
            cell.configure(with: channelId, isPlaying: isPlaying, programs: [], viewContext: viewContext)
        }
    }
    
    private func scrollToSelectedChannel(animated: Bool = true) {
        guard let _channelId = targetChannelId else { return }
        let index = channelMap?.map.firstIndex(of: _channelId) ?? 0
        let indexPath = IndexPath(row: index, section: 0)
        
        // Focus will be applied in scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
    }
    
    //MARK: - Private API - Focus
    
    private func applyFocus() {
        
        let visibleCells: [GuideRowCell] = self.tableView.visibleCells as? [GuideRowCell] ?? []
        
        guard let channelId = targetChannelId,
              let cell = visibleCells.first(where: { $0.channelId == channelId }) else {
            logDebug("Cell for targetChannelId not found in visible cells")
            return
        }
        
        let view = cell.channelNameView
        
        Task { @MainActor in
            
            // Check if we're now in the focus hierarchy
            if let focusSystem = UIFocusSystem.focusSystem(for: self),
               let currentFocus = focusSystem.focusedItem as? UIView {
                
                // Check if focus is somewhere in our view controller
                var responder: UIResponder? = currentFocus
                var isInOurHierarchy = false
                while let current = responder {
                    if current === self {
                        isInOurHierarchy = true
                        break
                    }
                    responder = current.next
                }
                
                if isInOurHierarchy {
                    self.requestFocus(on: view)
                } else {
                    // Request focus on ourselves first
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                    
                    // Then try again after another delay
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    self.requestFocus(on: view)
                }
            } else {
                self.requestFocus(on: view)
            }
        }
    }
    
    private func requestFocus(on view: PlatformView) {
        guard view.canBecomeFocused else {
            logDebug("View is not a focusable view")
            return
        }
        
        // Set the target view so preferredFocusEnvironments returns it
        self.targetFocusView = view
        
        // Request focus update on the view controller
        self.setNeedsFocusUpdate()
        self.updateFocusIfNeeded()
    }

    //MARK: - Internal API - Injected App State (from SwiftUI)
    
    // Set by GuideViewRepresentable.Coordinator
    var appState: AppStateProvider!
    
    // Set by GuideViewRepresentable.Coordinator
    var channelMap: ChannelMap!
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
}

// MARK: - UITableViewDataSource protocol

extension GuideViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return min(channelMap?.totalCount ?? 0, 1)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelMap?.totalCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let guideRowCell = tableView.dequeueReusableCell(withIdentifier: GuideRowCell.identifier, for: indexPath) as! GuideRowCell
        let channelId = channelMap.map[indexPath.row]
        let isPlaying = (appState.selectedChannel != nil && channelId == appState.selectedChannel)
        guideRowCell.configure(with: channelId,
                               isPlaying: isPlaying,
                               programs: [], //((indexPath.row % 2 == 0) ? self.channelPrograms : []),
                               viewContext: viewContext)
        guideRowCell.delegate = self
        return guideRowCell
    }
}

// MARK: - UITableViewDelegate protocol

extension GuideViewController: UITableViewDelegate {
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        Task { @MainActor in
            self.applyFocus()
        }
    }
}
