//
//  ProgramCollectionViewCell.swift
//  tvOS_HeckYeahTV
//
//  Created by Ed Hellyer on 1/22/26.
//  Copyright © 2026 Hellyer Multimedia. All rights reserved.
//

import UIKit

class ProgramCollectionViewCell: UICollectionViewCell {
    
    static let cellIdentifier: String = "GuideRowCell.ProgramsCollectionViewCell"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        programView.configure(with: nil,
                              isPlaying: false)
    }
    
    private func commonInit() {
        self.backgroundColor = .clear
        self.layer.masksToBounds = true
        self.layer.cornerRadius = AppStyle.cornerRadius
        longTapGesture.delegate = self
        addGestureRecognizer(longTapGesture)
    }
    
    lazy var programView: ProgramView = {
        let _programView = ProgramView()
        contentView.configureChildView(_programView)
        return _programView
    }()
    
    
    private lazy var longTapGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(viewTapped))
        gesture.cancelsTouchesInView = false
        gesture.delaysTouchesBegan = false
        gesture.delaysTouchesEnded = false
        gesture.minimumPressDuration = 0
        gesture.allowableMovement = 12
        return gesture
    }()
    
    //MARK: - Private API - Actions and action view modifiers
    
    @objc private func viewTapped(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
            case .began:
                onTapDownFocusEffect()
                
            case .ended, .changed, .cancelled, .failed:
                onTapUpFocusEffect()
                
            default:
                break
        }
    }
}

extension ProgramCollectionViewCell: @MainActor FocusTargetView {
    
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [self]
    }
    
    override var canBecomeFocused: Bool {
        return true
    }
    
    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        if (context.nextFocusedView === self) {
            self.becomeFocusedUsingAnimationCoordinator(in: context, with: coordinator) {
                [weak self] foregroundColor, backgroundColor in
                self?.programView.updateViewTintColor(foregroundColor)
            }
        } else if (context.previouslyFocusedView === self) {
            self.resignFocusUsingAnimationCoordinator(in: context, with: coordinator) {
                [weak self] foregroundColor, backgroundColor in
                self?.programView.updateViewTintColor(foregroundColor)
            }
        }
    }
}

//MARK: - UIGestureRecognizerDelegate

extension ProgramCollectionViewCell: UIGestureRecognizerDelegate {
    
    /// Allow the long press gesture to work simultaneously with other gestures (like the collection view's tap recognizer)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, 
                          shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /// Allow touches to be delivered to the view hierarchy (important for collection view selection)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, 
                          shouldReceive touch: UITouch) -> Bool {
        return true
    }
}




#Preview("UIKit Preview") {
    
    // Override the injected SwiftDataController
    let mockData = MockSwiftDataStack()
    let swiftDataController = MockSwiftDataController(viewContext: mockData.viewContext)
    InjectedValues[\.swiftDataController] = swiftDataController
    
    let channel = swiftDataController.previewOnly_fetchChannel(at: 11)
    let channelPrograms: [ChannelProgram] = swiftDataController.previewOnly_channelPrograms(channelId: channel.id)
    
    let view = ProgramCollectionViewCell()
    
    view.programView.configure(with: channelPrograms.first!, isPlaying: false)
    
    let heightConstraint = view.heightAnchor.constraint(equalToConstant: AppStyle.rowHeight)
    heightConstraint.priority = UILayoutPriority(1000)
    heightConstraint.isActive = true
    
    return view
}
