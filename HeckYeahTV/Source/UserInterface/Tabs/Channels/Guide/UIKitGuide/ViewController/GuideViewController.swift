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

class GuideViewController: UIViewController {

    //MARK: - UIViewController overrides
    
    deinit {
        logDebug("Deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupSearchController()
        setupTableView()
        setupAppStateObservation()
        
        // Make the view controller's view focusable so UIKit can take over focus
        self.view.isUserInteractionEnabled = true
       
        try? swiftDataController.deletePastChannelPrograms()
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
    
    private weak var targetFocusView: UIView?
    
//    private lazy var searchBar: UISearchBar = {
//        let searchBar = UISearchBar()
//        searchBar.placeholder = "Search channels by name"
//        searchBar.delegate = self
//        searchBar.searchBarStyle = .minimal
//        searchBar.sizeToFit()
//        return searchBar
//    }()
    
    private lazy var tableView: UITableView = {
        let _tableView = UITableView()
        _tableView.translatesAutoresizingMaskIntoConstraints = false
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
    
    @Injected(\.swiftDataController)
    private var swiftDataController: SwiftDataControllable
    private var section: SectionModel = 0
    private var reloadTableViewTask: Task<Void, Never>? = nil
    private var searchDebounceTask: Task<Void, Never>? = nil
    
    private var targetChannelId: ChannelId? {
        return appState.selectedChannel ?? swiftDataController.channelBundleMap.map.first
    }
    
//    private func setupSearchController() {
//        // On tvOS, add search bar as table header view
//        tableView.tableHeaderView = searchBar
//        
//        // Set initial search term if it exists
//        if let existingSearchTerm = appState?.searchTerm {
//            searchBar.text = existingSearchTerm
//        }
//    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.clipsToBounds = true
        tableView.register(GuideRowCell.self, forCellReuseIdentifier: GuideRowCell.identifier)
        tableView.allowsSelection = false
    }
    
    //MARK: - Observation of SharedAppState
    
    private func setupAppStateObservation() {
        
        withObservationTracking({
            // Access the property we care about. This registers the dependency.
            _ = swiftDataController.channelBundleMap.mapCount
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
                    self?.setupAppStateObservation()
                }
            }
        })
    }

    private func setPlayingChannel(id: ChannelId) throws {
        appState?.selectedChannel = id
        reloadVisibleRows()
    }
    
    private func toggleFavorite(id: ChannelId) throws {
        reloadVisibleRows()
    }

    private func reloadVisibleRows() {
        let cells = self.tableView.visibleCells as? [GuideRowCell] ?? []
        let selectedChannel = appState?.selectedChannel
        
        cells.forEach { cell in
            let channelId = cell.channelId ?? "666" // "666" will never be a valid channelId, but that is ok and safer than force unwrap.
            let isPlaying = selectedChannel == channelId
            if isPlaying {
                self.targetFocusView = cell.channelNameView
            }
            cell.configure(with: channelId,
                           isPlaying: isPlaying,
                           viewContext: viewContext)
        }
    }
    
    private func scrollToSelectedChannel(animated: Bool = true) {
        guard let _channelId = targetChannelId else { return }
        if let index = swiftDataController.channelBundleMap.map.firstIndex(of: _channelId) {
            let indexPath = IndexPath(row: index, section: 0)
            // Focus will be applied in scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        } else if swiftDataController.channelBundleMap.map.isEmpty == false {
            //Just scroll to the first item in the list when the target channelId is not found, AND there are channels in the list.
            let indexPath = IndexPath(row: 0, section: 0)
            tableView.scrollToRow(at: indexPath, at: .middle, animated: animated)
        }
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
    
    private func requestFocus(on view: UIView) {
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
    var viewContext: ModelContext!
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
        appState.showChannelPrograms = channelProgram
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
        let channelId = swiftDataController.channelBundleMap.map[indexPath.row]
        let isPlaying = (channelId == appState.selectedChannel)
        guideRowCell.configure(with: channelId,
                               isPlaying: isPlaying,
                               viewContext: viewContext)
        guideRowCell.delegate = self
        return guideRowCell
    }
}

// MARK: - UITableViewDelegate protocol

extension GuideViewController: UITableViewDelegate {
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        Task { @MainActor in
//            self.applyFocus()
//        }
    }
}

//// MARK: - UISearchBarDelegate protocol
//
//extension GuideViewController: UISearchBarDelegate {
//    
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        // Cancel any pending search task
//        searchDebounceTask?.cancel()
//        
//        // Debounce the search to avoid too many updates while typing
//        searchDebounceTask = Task { @MainActor in
//            do {
//                // Wait a bit for the user to finish typing
//                try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
//                try Task.checkCancellation()
//                
//                // Update the app state with the search term
//                // Empty string is converted to nil to clear the search
//                if !searchText.isEmpty {
//                    appState?.searchTerm = searchText
//                } else {
//                    appState?.searchTerm = nil
//                }
//                
//            } catch {
//                // Task was cancelled, do nothing
//            }
//        }
//    }
//}

