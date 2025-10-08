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
    
    private lazy var tableView: UITableView = {
        let _tableView = PlatformUtils.createTableView()
        view.addSubview(_tableView)
        _tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: _tableView.trailingAnchor).isActive = true
        _tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: _tableView.bottomAnchor).isActive = true
        _tableView.clipsToBounds = false
        _tableView.estimatedRowHeight = 120
        _tableView.sectionHeaderTopPadding = 0.0
        _tableView.rowHeight = UITableView.automaticDimension
        _tableView.sectionHeaderHeight = UITableView.automaticDimension
        _tableView.estimatedSectionHeaderHeight = 50
        return _tableView
    }()
    
    //MARK: - Private API
    
    typealias SectionModel = Int
    
    private var section: SectionModel = 0
    private lazy var viewContext = DataPersistence.shared.viewContext
    
    private lazy var dataSource = UITableViewDiffableDataSource<SectionModel, PersistentIdentifier>(tableView: self.tableView) { [weak self] tableView, indexPath, persistentIdentifier in
        let guideRowCell = tableView.dequeueReusableCell(withIdentifier: GuideRowCell.identifier, for: indexPath) as! GuideRowCell
        
        if let channel = self?.viewContext.model(for: persistentIdentifier) as? IPTVChannel {
            guideRowCell.configure(with: channel, programs: self?.channelPrograms ?? [])
            guideRowCell.delegate = self
        }
        return guideRowCell
    }
    
    //TODO: Integrate program data into GuideChannel
    private var channelPrograms: [Program] = Program.mockPrograms()
    
    private func setupTableView() {
        tableView.register(GuideRowCell.self, forCellReuseIdentifier: GuideRowCell.identifier)
    }
    
    private func registerObservers() {
        NotificationCenter.default.addObserver(forName: ModelContext.didSave, object: nil, queue: .main) { [weak self] notification in
            DispatchQueue.main.async {
                guard let self else { return }
                
                let changes = notification.dataChanges
                
                if !changes.inserted.isEmpty || !changes.deleted.isEmpty {
                    // structural changes → rebuild snapshot
                    self.applySnapshot(animated: true)
                } else if !changes.updated.isEmpty {
                    // content-only changes → reload those rows
                    var snap = self.dataSource.snapshot()
                    snap.reloadItems(Array(changes.updated))
                    self.dataSource.apply(snap, animatingDifferences: false)
                } else {
                    // last-resort: ensure visible rows refresh even if payload is empty
                    var snap = self.dataSource.snapshot()
                    let visible = self.tableView.indexPathsForVisibleRows?
                        .compactMap { self.dataSource.itemIdentifier(for: $0) } ?? []
                    snap.reconfigureItems(visible)
                    self.dataSource.apply(snap, animatingDifferences: false)
                }
            }
        }
    }
    
    //MARK: - Observation of SharedAppState
    
    private func setupAppStateObservation() {
        // If appState hasn't been injected yet, nothing to observe.
        guard let appState else { return }
        
        // Re-run when showFavoritesOnly changes.
        withObservationTracking({
            // Access the property we care about. This registers the dependency.
            _ = appState.showFavoritesOnly
        }, onChange: { [weak self] in
            // Called when any accessed observed property in the tracking block changes.
            Task { @MainActor [weak self] in
                self?.applySnapshot(animated: true)
            }
        })
    }
    
    private func applySnapshot(animated: Bool) {
        let channels: [PersistentIdentifier] = (try? self.getAllChannels().map(\.persistentModelID)) ?? []
        var snap = NSDiffableDataSourceSnapshot<SectionModel, PersistentIdentifier>()
        snap.appendSections([section])
        snap.appendItems(channels, toSection: section)
        dataSource.apply(snap, animatingDifferences: animated)
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

    private func getAllChannels() throws -> [IPTVChannel] {
        // Apply favorites filter based on appState.showFavoritesOnly.
        let sort = [SortDescriptor(\IPTVChannel.sortHint, order: .forward)]
        if appState?.showFavoritesOnly == true {
            let predicate = #Predicate<IPTVChannel> { $0.isFavorite == true }
            let descriptor = FetchDescriptor<IPTVChannel>(predicate: predicate, sortBy: sort)
            return try viewContext.fetch(descriptor)
        } else {
            let descriptor = FetchDescriptor<IPTVChannel>(sortBy: sort)
            return try viewContext.fetch(descriptor)
        }
    }
    

    //MARK: - Internal API - Injected App State (from SwiftUI)
    
    // Set by GuideViewRepresentable.Coordinator
    var appState: SharedAppState! {
        didSet {
            // If the controller is already loaded and we get a new instance, rewire observation.
            if isViewLoaded {
                setupAppStateObservation()
                // Re-apply snapshot in case filter intent changed with a new instance.
                applySnapshot(animated: true)
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
