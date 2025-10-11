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
        print("GuideViewController deallocated")
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupAppStateObservation()
        applySnapshot(animated: false)
        registerObservers()
    }
    
    //MARK: - Private API - Lazy binding vars
    
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
    
#if os(macOS)
    // Simple backing array for macOS; we’ll reloadData on changes
    private var macItems: [PersistentIdentifier] = []
#else
    private lazy var dataSource = UITableViewDiffableDataSource<SectionModel, PersistentIdentifier>(tableView: self.tableView) { [weak self] tableView, indexPath, persistentIdentifier in
        let guideRowCell = tableView.dequeueReusableCell(withIdentifier: GuideRowCell.identifier, for: indexPath) as! GuideRowCell
        
        if let channel = self?.viewContext.model(for: persistentIdentifier) as? IPTVChannel {
            guideRowCell.configure(with: channel, programs: self?.channelPrograms ?? [])
            guideRowCell.delegate = self
        }
        return guideRowCell
    }
#endif
    
    //TODO: Integrate program data into GuideChannel
    private var channelPrograms: [Program] = Program.mockPrograms()
    
    private func setupTableView() {
#if os(macOS)
        tableView.delegate = self
        tableView.dataSource = self
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
        //tableView.separatorStyle = .none
        tableView.allowsSelection = false
#endif
    }
    
    private func registerObservers() {
        NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil, queue: .main) { [weak self] notification in
            DispatchQueue.main.async {
                guard let self else { return }

                let changes = notification.dataChanges

                if not(changes.inserted.isEmpty) || not(changes.deleted.isEmpty) {
                    // Structural changes → rebuild snapshot
                    self.applySnapshot(animated: true)
                    return
                }

                if !changes.updated.isEmpty {
                    // Updated may affect current filter membership (e.g., isFavorite toggled)
                    // Safest: When show favorites is on, rebuild snapshot so filtered-out items disappear and new matches appear.
                    if self.appState.showFavoritesOnly {
                        self.applySnapshot(animated: false)
                    }
                    
#if !os(macOS)
                    // Then refresh updated rows that remain visible for any non-structural visual updates.
                    var snap = self.dataSource.snapshot()
                    let stillVisible = Array(changes.updated).filter { snap.itemIdentifiers.contains($0) }
                    if !stillVisible.isEmpty {
                        snap.reloadItems(stillVisible)
                        self.dataSource.apply(snap, animatingDifferences: false)
                    }
#endif
                    return
                }

                // No explicit payload — ensure UI stays in sync with store.
                self.applySnapshot(animated: false)
#if !os(macOS)
                var snap = self.dataSource.snapshot()
                let visible = self.tableView.indexPathsForVisibleRows?.compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
                if !visible.isEmpty {
                    snap.reconfigureItems(visible)
                    self.dataSource.apply(snap, animatingDifferences: false)
                }
#endif
            }
        }
    }
    
    //MARK: - Observation of SharedAppState
    
    private func setupAppStateObservation() {
        // If appState hasn't been injected yet, nothing to observe.
        guard let appState else { return }
        
        withObservationTracking({
            // Access the property we care about. This registers the dependency.
            _ = appState.showFavoritesOnly
        }, onChange: { [weak self] in
            // Called when any accessed observed property in the tracking block changes.
            Task { @MainActor [weak self] in
                self?.applySnapshot(animated: false)
                
                // Rearm observation tracking
                self?.setupAppStateObservation()
            }
        })
    }
    
    private func applySnapshot(animated: Bool) {
        let channels: [PersistentIdentifier] = self.fetchChannelListIdentifiers()
#if os(macOS)
        self.macItems = channels
        self.tableView.reloadData()
#else
        var snap = NSDiffableDataSourceSnapshot<SectionModel, PersistentIdentifier>()
        snap.appendSections([section])
        snap.appendItems(channels, toSection: section)
        dataSource.apply(snap, animatingDifferences: animated)
#endif
    }

    private func setPlayingChannel(id: String) throws {
        /// There can only be one channel at a time playing, this code enforces that demand.
        let isPlayingPredicate = #Predicate<IPTVChannel> { $0.isPlaying }
        let isPlayingDescriptor = FetchDescriptor<IPTVChannel>(predicate: isPlayingPredicate)
        let channels = try viewContext.fetch(isPlayingDescriptor)
        
        let targetChannelPredicate = #Predicate<IPTVChannel> { $0.id == id }
        var targetChannelDescriptor = FetchDescriptor<IPTVChannel>(predicate: targetChannelPredicate)
        targetChannelDescriptor.fetchLimit = 1
        let targetChannel = try viewContext.fetch(targetChannelDescriptor).first
        
        for channel in channels {
            channel.isPlaying = false
        }
        targetChannel?.isPlaying = true
        
        try viewContext.save()
    }
    
    private func toggleFavorite(id: String) throws {
        let predicate = #Predicate<IPTVChannel> { $0.id == id }
        var descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate)
        descriptor.fetchLimit = 1
        if let channel = try viewContext.fetch(descriptor).first {
            channel.isFavorite.toggle()
            try viewContext.save()
        }
    }

    private func fetchChannelListIdentifiers() -> [PersistentIdentifier] {
        let sort = [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
        var descriptor: FetchDescriptor<IPTVChannel> = FetchDescriptor<IPTVChannel>(sortBy: sort)
        descriptor.propertiesToFetch = [\.sortHint]
        if appState?.showFavoritesOnly == true {
            let predicate = #Predicate<IPTVChannel> { $0.isFavorite == true }
            descriptor.predicate = predicate
        }
        let results = (try? viewContext.fetch(descriptor)) ?? []
        return results.map((\.persistentModelID))
    }
    
#if os(tvOS)
    /// Programmatically set focus to a specific target within the table, if visible.
//    func setFocus(_ target: FocusTarget) {
//        guard case let .guide(channelId, _) = target else { return }
//        
//        guard let indexPath = indexPath(forChannelId: channelId) else { return }
//        // If cell is not realized, scroll first then resolve on the next runloop.
//        if tableView.cellForRow(at: indexPath) == nil {
//            tableView.scrollToRow(at: indexPath, at: .none, animated: false)
//            DispatchQueue.main.async { [weak self] in
//                self?.applyFocus(target, at: indexPath)
//            }
//        } else {
//            applyFocus(target, at: indexPath)
//        }
//    }
//    
//    private func applyFocus(_ target: FocusTarget, at indexPath: IndexPath) {
//        guard let cell = tableView.cellForRow(at: indexPath) as? GuideRowCell,
//              let view = cell.focusableView(for: target) else { return }
//        requestFocus(on: view)
//    }
//    
//    private func requestFocus(on view: UIView) {
//        guard view.canBecomeFocused else { return }
//        if let system = UIFocusSystem.focusSystem(for: self.view) {
//            system.requestFocusUpdate(to: view)
//            system.updateFocusIfNeeded()
//        }
//    }
//    
//    private func indexPath(forChannelId channelId: String) -> IndexPath? {
//        let snapshot = dataSource.snapshot()
//        for (row, itemId) in snapshot.itemIdentifiers.enumerated() {
//            if let channel = viewContext.model(for: itemId) as? IPTVChannel, channel.id == channelId {
//                return IndexPath(row: row, section: section)
//            }
//        }
//        return nil
//    }
#endif
    
    //MARK: - Internal API - Injected App State (from SwiftUI)
    
    // Set by GuideViewRepresentable.Coordinator
    var appState: SharedAppState!
    {
        didSet {
            if isViewLoaded {
                setupAppStateObservation()
            }
        }
    }
    
    //MARK: - Internal API
    
    weak var delegate: GuideViewControllerDelegate?
}

//MARK: - GuideViewDelegate protocol

extension GuideViewController: GuideViewDelegate {
    
    func didBecomeFocused(target: FocusTarget) {
        delegate?.setFocus(target)
    }
    
    func selectChannel(_ channel: IPTVChannel) {
        try? self.setPlayingChannel(id: channel.id)
    }
    
    func toggleFavoriteChannel(_ channel: IPTVChannel) {
        try? self.toggleFavorite(id: channel.id)
    }
}

#if os(macOS)
// MARK: - NSTableViewDataSource/Delegate
extension GuideViewController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        macItems.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier(GuideRowCell.identifier)
        let reusable = tableView.makeView(withIdentifier: id, owner: self) as? GuideRowCell ?? {
            let cell = GuideRowCell(frame: .zero)
            cell.identifier = id
            return cell
        }()
        
        let persistentId = macItems[row]
        if let channel = viewContext.model(for: persistentId) as? IPTVChannel {
            reusable.configure(with: channel, programs: channelPrograms)
            reusable.delegate = self
        }
        return reusable
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        140 // Approximate row height; adjust as needed
    }
}
#endif


