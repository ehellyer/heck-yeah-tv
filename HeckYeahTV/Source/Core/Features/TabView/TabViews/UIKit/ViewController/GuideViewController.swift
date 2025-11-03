//
//  GuideViewController.swift
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
        
#if os(tvOS)
        logDebug("🎯 GuideViewController appeared!")

        // Make the view controller's view focusable so UIKit can take over focus
        self.view.isUserInteractionEnabled = true

        // CRITICAL: Force focus into our view hierarchy
        // This is necessary because SwiftUI TabView captures focus by default
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            logDebug("🎯 Requesting focus for table view")
            self.setNeedsFocusUpdate()
            self.updateFocusIfNeeded()
            self.scrollToSelectedChannelAndFocus()
        }
#endif
    }
    
#if os(tvOS)
    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
        // If we have a specific target view, prefer it
        if let targetView = self.targetFocusView {
            logDebug("Preferred focus: target view \(targetView)")
            return [targetView]
        }
        // Otherwise prefer the table view so focus can enter our hierarchy
        logDebug("Preferred focus: table view")
        return [self.tableView]
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        // Clear the target once it receives focus
        if let targetView = targetFocusView, context.nextFocusedItem as? UIView == targetView {
            targetFocusView = nil
            logDebug("Target view received focus successfully")
        }
        
        // Log focus changes for debugging
        logDebug("Focus update - Previous: \(String(describing: context.previouslyFocusedItem))")
        logDebug("Focus update - Next: \(String(describing: context.nextFocusedItem))")
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        // Always allow focus updates
        logDebug("shouldUpdateFocus called")
        return true
    }
#endif
    
    //MARK: - Private API - Lazy binding vars
    
    private weak var targetFocusView: PlatformView?
    
    private lazy var tableView: PlatformTableView = {
        let _tableView = PlatformUtils.createTableView()
        view.addSubview(_tableView)
        _tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: _tableView.trailingAnchor).isActive = true
#if os(macOS)
        _tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: _tableView.bottomAnchor).isActive = true
#else
        _tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: _tableView.bottomAnchor).isActive = true
#endif
#if os(macOS)
        // NSTableView sizing handled by delegate methods; no estimatedRowHeight
#else
        _tableView.clipsToBounds = false
        _tableView.estimatedRowHeight = 120
        if #available(iOS 15.0, tvOS 15.0, *) {
            _tableView.sectionHeaderTopPadding = 0.0
        }
        _tableView.rowHeight = UITableView.automaticDimension
        _tableView.sectionHeaderHeight = UITableView.automaticDimension
        _tableView.estimatedSectionHeaderHeight = 50
#endif
        return _tableView
    }()
    
    //MARK: - Private API
    
    typealias SectionModel = Int
    private var section: SectionModel = 0
    private lazy var viewContext = DataPersistence.shared.viewContext
    private var reloadTableViewTask: Task<Void, Never>? = nil
    
    //TODO: Integrate program data into IPTVChannel
    private var channelPrograms: [Program] = Program.mockPrograms()
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
#if os(macOS)
        tableView.headerView = nil
        tableView.selectionHighlightStyle = .none
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.rowSizeStyle = .default
        // Register identifier for reusable cell view
        tableView.register(NSNib(), forIdentifier: NSUserInterfaceItemIdentifier(GuideRowCell.identifier))
#else
        tableView.register(GuideRowCell.self, forCellReuseIdentifier: GuideRowCell.identifier)
        tableView.allowsSelection = false
        
        #if os(tvOS)
        // CRITICAL: These settings allow the table view to participate in the focus system
        tableView.remembersLastFocusedIndexPath = true
        tableView.clipsToBounds = false
        tableView.contentInsetAdjustmentBehavior = .never
        #endif
#endif
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
                        try await Task.sleep(nanoseconds: 300_000_000)
                        try Task.checkCancellation()
                        self?.tableView.reloadData()
                        self?.scrollToSelectedChannelAndFocus()
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
#if os(macOS)
        // On macOS, NSTableView uses different methods
        let visibleRect = tableView.visibleRect
        let visibleRange = tableView.rows(in: visibleRect)
        if visibleRange.length > 0 {
            let indexSet = IndexSet(integersIn: visibleRange.location..<(visibleRange.location + visibleRange.length))
            tableView.reloadData(forRowIndexes: indexSet, columnIndexes: IndexSet(integer: 0))
        }
#else
        // On iOS/tvOS, UITableView uses indexPaths
        let indexPaths = self.tableView.indexPathsForVisibleRows ?? []
        indexPaths.forEach { indexPath in
            logDebug("Refreshing cell at indexPath: \(indexPath)")
            let channelId = channelMap.map[indexPath.row]
            let isPlaying = appState?.selectedChannel == channelId
            let cell = self.tableView.cellForRow(at: indexPath) as? GuideRowCell
            cell?.configure(with: channelId, isPlaying: isPlaying, programs: [], viewContext: viewContext)
        }
#endif
    }
    
    private func requestFocus(on view: UIView) {
        logDebug("Focus requested for view: \(view)")
        guard view.canBecomeFocused else {
            logDebug("View is not a focusable view")
            return
        }
   
        // Set the target view so preferredFocusEnvironments returns it
        self.targetFocusView = view
        
        // Check if we're already in the focus hierarchy
        let focusSystem = UIFocusSystem.focusSystem(for: self)
        let currentlyFocusedItem = focusSystem?.focusedItem
        
        logDebug("Current focused item: \(String(describing: currentlyFocusedItem))")
        logDebug("Is view in focus hierarchy: \(view.canBecomeFocused)")
        
        // Request focus update on the view controller
        self.setNeedsFocusUpdate()
        self.updateFocusIfNeeded()
        
        logDebug("Requested Focus on view \(view)")
    }
    
    func applyFocus(at indexPath: IndexPath) {
        
        let visibleCells: [GuideRowCell] = self.tableView.visibleCells as? [GuideRowCell] ?? []
        
        guard let channelId = channelMap?.map[indexPath.row],
              let cell = visibleCells.first(where: { $0.channelId == channelId }) else {
            logDebug("Cell for row \(indexPath.row) not found in visible cells")
            return
        }
        
        let view = cell.channelNameView
        logDebug("applyFocus: Preparing to focus on view in cell at \(indexPath)")
        
        Task { @MainActor in
          
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Check if we're now in the focus hierarchy
            if let focusSystem = UIFocusSystem.focusSystem(for: self),
               let currentFocus = focusSystem.focusedItem as? UIView {
                logDebug("Current focused item: \(currentFocus)")
                
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
                    logDebug("We're in the focus hierarchy, requesting specific view focus")
                    self.requestFocus(on: view)
                } else {
                    logDebug("Not in focus hierarchy yet, requesting VC focus first")
                    // Request focus on ourselves first
                    self.setNeedsFocusUpdate()
                    self.updateFocusIfNeeded()
                    
                    // Then try again after another delay
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    self.requestFocus(on: view)
                }
            } else {
                logDebug("No focus system available")
                self.requestFocus(on: view)
            }
        }
    }
    
    func scrollToSelectedChannelAndFocus() {
        guard let channelId = appState.selectedChannel ?? channelMap.map.first,
              let index = index(forChannelId: channelId)
        else {
            return
        }
        
#if os(macOS)
        tableView.scrollRowToVisible(index)
#else
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        // Focus will be applied in scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView)
#endif
    }

    private func index(forChannelId channelId: String?) -> Int? {
        guard let channelId,
              let index = channelMap.map.firstIndex(of: channelId)
        else {
            return nil
        }
        return index
    }
    
    private func debugFocusHierarchy(for view: UIView) {
        logDebug("=== Focus Hierarchy Debug ===")
        logDebug("View: \(view)")
        logDebug("canBecomeFocused: \(view.canBecomeFocused)")
        logDebug("isUserInteractionEnabled: \(view.isUserInteractionEnabled)")
        
        var currentEnvironment: UIFocusEnvironment? = view
        var depth = 0
        while let env = currentEnvironment, depth < 10 {
            logDebug("  [\(depth)] \(env)")
            currentEnvironment = env.parentFocusEnvironment
            depth += 1
        }
        logDebug("===========================")
    }
    
    
    //MARK: - Internal API - Injected App State (from SwiftUI)
    
    // Set by GuideViewRepresentable.Coordinator
    var appState: SharedAppState!
    
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

#if os(macOS)

// MARK: - NSTableViewDataSource/Delegate protocol

extension GuideViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return channelMap?.totalCount ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier(GuideRowCell.identifier)
        let guideRowCell = tableView.makeView(withIdentifier: id, owner: self) as? GuideRowCell ?? {
            let cell = GuideRowCell(frame: .zero)
            return cell
        }()
        let channelId = channelMap.map[row]
        let isPlaying = (appState.selectedChannel != nil && channelId == appState.selectedChannel)
        guideRowCell.configure(with: channelId,
                       isPlaying: isPlaying,
                       programs: ((row % 2 == 0) ? self.channelPrograms : []),
                       viewContext: viewContext)
        guideRowCell.delegate = self
       
        return guideRowCell
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        140 // Approximate row height; adjust as needed
    }
}

#else

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

#endif


#if !os(macOS)
extension GuideViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Cell scrolled off screen
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Called when programmatic scroll animation completes
        logDebug("Scroll animation ended")
        
        guard let channelId = appState.selectedChannel,
              let index = index(forChannelId: channelId) else { return }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        Task { @MainActor in
            self.applyFocus(at: indexPath)
        }
    }
}
#endif
