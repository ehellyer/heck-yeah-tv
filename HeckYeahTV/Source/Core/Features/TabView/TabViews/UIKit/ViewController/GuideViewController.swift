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

protocol GuideViewControllerDelegate: AnyObject {
    /// Ask delegate to update the focus target to this target.
    func setFocus(_ target: FocusTarget)
}

class GuideViewController: PlatformViewController {

    //MARK: - PlatformViewController overrides
    
    deinit {
        logDebug("Deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupAppStateObservation()
    }
    
#if os(tvOS)
    override var preferredFocusEnvironments: [any UIFocusEnvironment] {
        if let tfv = self.targetFocusView {
            return [tfv]
        }
        return self.preferredFocusEnvironments
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        if context.nextFocusedItem as? PlatformView == targetFocusView {
            targetFocusView = nil
        }
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
    
    //TODO: Integrate program data into GuideChannel
    private var channelPrograms: [Program] = Program.mockPrograms()
    
    private func setupTableView() {
        //tableView.delegate = self
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
        tableView.reloadRows(at: indexPaths, with: .automatic)
#endif
    }
    
    
//    func focusImmediately(_ view: UIView, from env: UIFocusEnvironment) {
//        guard view.canBecomeFocused else {
//            logDebug("View is not a focusable view")
//            return
//        }
//        
//        // Get the focus system for this environment (API is deprecated on newer SDKs; use #available if needed)
//        if let system = UIFocusSystem.focusSystem(for: env) {
//            system.requestFocusUpdate(to: view)
//            system.updateFocusIfNeeded()
//        }
//    }
    
    private func requestFocus(on view: UIView) {
        logDebug("Focus requested")
        guard view.canBecomeFocused else {
            logDebug("View is not a focusable view")
            return
        }
   
        self.targetFocusView = view
        let env = self.parentFocusEnvironment ?? self
        if let system = UIFocusSystem.focusSystem(for: env) {
            logDebug("Focus system available")
            system.requestFocusUpdate(to: view)
            system.updateFocusIfNeeded()
        } else {
            logDebug("No focus system available for view")
        }
    }
    
    private func applyFocus(_ target: FocusTarget, at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? GuideRowCell,
              let view = cell.focusableView(for: target) else { return }
        requestFocus(on: view)
    }
    
    private func scrollToSelectedChannel() {
        guard let channelId = appState.selectedChannel,
              let index = index(forChannelId: channelId)
        else {
            return
        }
        
#if os(macOS)
        tableView.scrollRowToVisible(index)
#else
        let indexPath = IndexPath(row: index, section: 0)
        tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.applyFocus(FocusTarget.guide(channelId: channelId, col: 1), at: indexPath)
        }
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
    
    //MARK: - Internal API - Injected App State (from SwiftUI)
    
    // Set by GuideViewRepresentable.Coordinator
    var appState: SharedAppState! {
        didSet {
            if self.isViewLoaded {
                DispatchQueue.main.async {
                    self.scrollToSelectedChannel()
                }
            }
        }
    }
    
    // Set by GuideViewRepresentable.Coordinator
    var channelMap: ChannelMap!
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewControllerDelegate?
}

//MARK: - GuideViewDelegate protocol

extension GuideViewController: GuideViewDelegate {
        
    func didBecomeFocused(target: FocusTarget) {
        delegate?.setFocus(target)
    }
    
    func selectChannel(_ channelId: ChannelId) {
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
                               programs: ((indexPath.row % 2 == 0) ? self.channelPrograms : []),
                               viewContext: viewContext)
        guideRowCell.delegate = self
        return guideRowCell
    }
}

#endif


