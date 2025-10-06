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

protocol GuideViewControllerDelegate: AnyObject {
    /// Ask delegate to update the focus target to this target.
    func setFocus(_ target: FocusTarget)
    
}

class GuideViewController: PlatformViewController {

    //MARK: - PlatformViewController overrides
    
    deinit {
        print("GuideViewController deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
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
    private lazy var viewContext = Persistence.shared.viewContext
    private var didSaveObserver: Any?
    
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
                
                let changes = notification.sdChanges
                
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
                    self.dataSource.apply(snap, animatingDifferences: true)
                }
                
                self.applySnapshot(animated: true)
            }
        }
    }
    
    func applySnapshot(animated: Bool) {
        let channels: [PersistentIdentifier] = (try? guideStore.getAllChannels().map(\.persistentModelID)) ?? []
        var snap = NSDiffableDataSourceSnapshot<SectionModel, PersistentIdentifier>()
        snap.appendSections([section])
        snap.appendItems(channels, toSection: section)
        dataSource.apply(snap, animatingDifferences: animated)
    }
    
    //MARK: - Internal API - Updates
    
    weak var delegate: GuideViewControllerDelegate?
    
    var guideStore: GuideStore = GuideStore()
}

//MARK: - GuideViewDelegate protocol

extension GuideViewController: GuideViewDelegate {
    @MainActor
    func didBecomeFocused(target: FocusTarget) {
        delegate?.setFocus(target)
    }
    
    @MainActor
    func selectChannel(_ channel: IPTVChannel) {
        try? guideStore.setPlayingChannel(id: channel.id)
    }
    
    @MainActor
    func toggleFavoriteChannel(_ channel: IPTVChannel) {
        try? guideStore.toggleFavorite(id: channel.id)
    }
}
