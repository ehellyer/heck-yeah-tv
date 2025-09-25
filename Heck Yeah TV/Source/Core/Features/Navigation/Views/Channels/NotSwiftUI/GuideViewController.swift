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

protocol GuideViewControllerDelegate: AnyObject {
    
    /// Ask delegate to set this channel as the selected channel.
    func channelSelected(_ channel: GuideChannel) -> Void
    
    /// Ask delegate to toggle the isFavorite state of this channel.
    func favoriteToggled(_ channel: GuideChannel) -> Void
    
    /// Ask delegate, is this channel a favorite channel?
    func isFavoriteChannel(_ channel: GuideChannel) -> Bool
    
    /// Ask delegate, is this the selected channel?
    func isSelectedChannel(_ channel: GuideChannel) -> Bool
    
    
    func setFocused(target: FocusTarget)
    
    func removeFocused(target: FocusTarget)
    
}

class GuideViewController: PlatformViewController {

    //MARK: - PlatformViewController overrides
    
    deinit {
        print("GuideViewController deallocated")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = false
        setupTableView()
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
    
    private var channels: [GuideChannel] = []
    //TODO: Integrate program data into GuideChannel
    private var channelPrograms: [Program] = Program.mockPrograms()
    
    private func setupTableView() {
        tableView.register(GuideRowCell.self, forCellReuseIdentifier: GuideRowCell.identifier)
        tableView.dataSource = self
    }
    
    //MARK: - Internal API - Updates
    
    weak var delegate: GuideViewControllerDelegate?
    
    func updateView(channels: [GuideChannel], channelPrograms: [Program]) {
        self.channels = channels
        tableView.reloadData()
    }
}

//MARK: - UITableViewDataSource protocol
extension GuideViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let guideRowCell = tableView.dequeueReusableCell(withIdentifier: GuideRowCell.identifier, for: indexPath) as! GuideRowCell
      
        let channel = channels[row]
        let programs = channelPrograms
        let isFavorite: Bool = delegate?.isFavoriteChannel(channel) ?? false
        let isSelectedChannel: Bool = delegate?.isSelectedChannel(channel) ?? false
        
        guideRowCell.configure(with: channel, programs: programs, isFavorite: isFavorite, isSelectedChannel: isSelectedChannel)
        guideRowCell.delegate = self
        return guideRowCell
    }
}

//MARK: - FocusViewDelegate protocol
extension GuideViewController: GuideFocusViewDelegate {
    func didBecomeFocused(target: FocusTarget) {
        delegate?.setFocused(target: target)
    }
    
    func didLoseFocus(target: FocusTarget) {
        //Confirm if this is needed.
        //delegate?.removeFocused(target: target)
    }
    
    func selectChannel(_ channel: GuideChannel) {
        self.delegate?.channelSelected(channel)
    }
    
    func toggleFavoriteChannel(_ channel: GuideChannel) {
        self.delegate?.favoriteToggled(channel)
    }
}
