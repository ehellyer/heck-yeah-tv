//
//  FocusTargetView+FocusAnimation.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

protocol FocusTargetView {
    
    typealias ViewBlock = (UIColor) -> Void
    
    func becomeFocusedUsingAnimationCoordinator(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator, viewBlock: ViewBlock?)
    
    func resignFocusUsingAnimationCoordinator(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator, viewBlock: ViewBlock?)
    
    func onTapDownFocusEffect()
    
    func onTapUpFocusEffect()
}

extension FocusTargetView where Self: UIView {
    
    private var scaleUp: CGFloat { return 1.05 }
    private var scaleDown: CGFloat { return 0.95 }
    private var selectedLayerName: String { return "selectedEffectLayer" }
    
    private func addParallaxMotionEffects(tiltValue: CGFloat = 0.25, panValue: CGFloat = 5.0) {
        let yRotation = UIInterpolatingMotionEffect(keyPath: "layer.transform.rotation.y", type: .tiltAlongHorizontalAxis)
        yRotation.minimumRelativeValue = tiltValue
        yRotation.maximumRelativeValue = -tiltValue
        let xRotation = UIInterpolatingMotionEffect(keyPath: "layer.transform.rotation.x", type: .tiltAlongVerticalAxis)
        xRotation.minimumRelativeValue = -tiltValue
        xRotation.maximumRelativeValue = tiltValue
        
        let xPan = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)
        xPan.minimumRelativeValue = -panValue
        xPan.maximumRelativeValue = panValue
        let yPan = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
        yPan.minimumRelativeValue = -panValue
        yPan.maximumRelativeValue = panValue
        
        let motionGroup = UIMotionEffectGroup()
        motionGroup.motionEffects = [yRotation, xRotation, xPan, yPan]
        self.addMotionEffect( motionGroup )
    }
    
    private func removeParallaxMotionEffects() {
        self.motionEffects = []
    }
    
    func becomeFocusedUsingAnimationCoordinator(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator, viewBlock: ViewBlock? = nil) {
        viewBlock?(UIColor.guideForegroundFocus)
        coordinator.addCoordinatedAnimations({ () -> Void in
            var rotationMatrix = CATransform3DIdentity
            rotationMatrix.m34 = -0.001 //(1.0 / -1000.0) - Perspective effect based on distance to the views eye (in camera space).
            rotationMatrix = CATransform3DTranslate(rotationMatrix, 0, 0, 0)
            let rotationAndScaleMatrix = CATransform3DScale(rotationMatrix, self.scaleUp, self.scaleUp, 1)
            self.layer.transform = rotationAndScaleMatrix
            
            if context.nextFocusedView?.layer.sublayers?.first(where: { $0.name == self.selectedLayerName }) == nil {
                let newLayer = CALayer()
                newLayer.frame = self.bounds
                newLayer.name = self.selectedLayerName
                newLayer.backgroundColor = UIColor.guideBackgroundFocus.cgColor
                context.nextFocusedView?.layer.insertSublayer(newLayer, at: 0)
            }
            self.addParallaxMotionEffects()
            
        }) { () -> Void in
            // Do nothing for completion
        }
    }
    
    func resignFocusUsingAnimationCoordinator(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator, viewBlock: ViewBlock? = nil) {
        viewBlock?(UIColor.guideForegroundNoFocus)
        coordinator.addCoordinatedAnimations({ () -> Void in
            self.layer.transform = CATransform3DIdentity
            if let layer = context.previouslyFocusedView?.layer.sublayers?.first(where: { $0.name == self.selectedLayerName }) {
                layer.removeFromSuperlayer()
            }
            self.removeParallaxMotionEffects()
        }) { () -> Void in
            // Do nothing for completion
        }
    }
    
    func onTapDownFocusEffect() {
        UIView.animate(withDuration: 0.1) {
            let scale: CGFloat = 1
            let matrix = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
            self.layer.transform = matrix
        }
    }
    
    func onTapUpFocusEffect() {
        UIView.animate(withDuration: 0.1) {
            let scale: CGFloat = self.scaleUp
            let matrix = CATransform3DScale(CATransform3DIdentity, scale, scale, 1)
            self.layer.transform = matrix
        }
    }
}
