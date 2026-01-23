//
//  FocusTargetView+FocusAnimation.swift
//  Heck Yeah TV
//
//  Created by Ed Hellyer on 9/23/25.
//  Copyright © 2025 Hellyer Multimedia. All rights reserved.
//

import UIKit

protocol FocusTargetView {
    
    typealias ViewBlock = (_ foregroundColor: UIColor, _ backgroundColor: UIColor) -> Void
    
    func becomeFocusedUsingAnimationCoordinator(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator, viewBlock: ViewBlock?)
    
    func resignFocusUsingAnimationCoordinator(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator, viewBlock: ViewBlock?)
    
    func onTapDownFocusEffect()
    
    func onTapUpFocusEffect()
}

extension FocusTargetView where Self: UIView {
    
    /// The number of pixels to grow on each side when focused
    private var focusGrowthInPixels: CGFloat { return 4.0 }
    
    /// The number of pixels to shrink on each side when pressed
    private var pressedShrinkInPixels: CGFloat { return 1.0 }
    
    /// Calculate scale factor based on adding fixed pixels to the view's dimensions
    private func scaleForPixelGrowth(_ pixels: CGFloat) -> CGFloat {
        
        let referenceSize = max(bounds.width, bounds.height)
        guard referenceSize > 0 else { return 1.0 }
        
        // Calculate how much bigger the view should be: (size + 2*pixels) / size
        // We multiply by 2 because pixels grow on both sides
        return (referenceSize + (pixels * 2)) / referenceSize
    }
    
    /// Scale factor for focused state (grows by focusGrowthInPixels)
    private var scaleUp: CGFloat { 
        return scaleForPixelGrowth(focusGrowthInPixels)
    }
    
    /// Scale factor for pressed state (shrinks by pressedShrinkInPixels)
    private var scaleDown: CGFloat { 
        return scaleForPixelGrowth(-pressedShrinkInPixels)
    }
    
    private var selectedLayerName: String { return "selectedEffectLayer" }
    
    private func addParallaxMotionEffects(panValue: CGFloat = 5.0) {
        // Calculate tilt based on view size - larger views need less tilt
        // Using 60 as the reference: a 600px view gets 0.1 tilt, a 300px view gets 0.2 tilt
        let longestSide = max(bounds.width, bounds.height)
        let tiltValue = longestSide > 0 ? min(60.0 / longestSide, 0.25) : 0.15
        
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
        viewBlock?(UIColor.guideForegroundFocused, UIColor.guideBackgroundFocused)
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
                newLayer.backgroundColor = UIColor.guideBackgroundFocused.cgColor
                context.nextFocusedView?.layer.insertSublayer(newLayer, at: 0)
            }
            self.addParallaxMotionEffects()
            
        }) { () -> Void in
            // Do nothing for completion
        }
    }
    
    func resignFocusUsingAnimationCoordinator(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator, viewBlock: ViewBlock? = nil) {
        viewBlock?(UIColor.guideForegroundNoFocus, UIColor.guideBackgroundNoFocus)
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
            let scale: CGFloat = self.scaleDown
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
