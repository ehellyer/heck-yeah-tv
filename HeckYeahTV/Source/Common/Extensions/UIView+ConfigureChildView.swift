//
//  UIView+ConfigureChildView.swift
//  UIKit Utilities
//
//  Created by Ed Hellyer on 6/5/19.
//  Copyright © 2019 Hellyer Multimedia. All rights reserved.
//


import UIKit

extension UIView {
    
    //MARK: - Private API
    
    private func addXibView(view: UIView) {
        self.transform = CGAffineTransform.identity
        UIView.configureChildView(view, inParentView: self, withInset: UIEdgeInsets.zero)
    }
    
    //MARK: - Public API
    
    func configureWithNib(_ name: String) {
        let bundle = Bundle(for: type(of: self))
        let xibView = UINib.init(nibName: name, bundle: bundle).instantiate(withOwner: self, options: nil)[0] as! UIView
        self.addXibView(view: xibView)
    }
    
    func configureChildView(_ childView: UIView, withInset edgeInsets: UIEdgeInsets = .zero) {
        UIView.configureChildView(childView, inParentView: self, withInset: edgeInsets)
    }

    func configureHCenteredChildView(_ childView: UIView, withInset edgeInsets: UIEdgeInsets) {
        UIView.configureHCenteredChildView(childView, inParentView: self, withInset: edgeInsets)
    }
    
    func configureChildView(_ childView: UIView,
                            withInset edgeInsets: UIEdgeInsets,
                            horizontalVisualFormat: String,
                            verticalVisualFormat: String) {
        UIView.configureChildView(childView,
                                  inParentView: self,
                                  withInset: edgeInsets,
                                  horizontalVisualFormat: horizontalVisualFormat,
                                  verticalVisualFormat: verticalVisualFormat)
    }
    
    //MARK: - Public Class API

    class func configureHCenteredChildView(_ childView: UIView,
                                  inParentView parentView: UIView,
                                  withInset edgeInsets: UIEdgeInsets) {
        UIView.configureChildView(childView,
                                  inParentView: parentView,
                                  withInset: edgeInsets,
                                  horizontalVisualFormat: "H:|-(>=left)-[view]-(>=right)-|",
                                  verticalVisualFormat: "V:|-top-[view]-bottom-|")
        
        parentView.addConstraint(NSLayoutConstraint(item: childView,
                                                    attribute: .centerX,
                                                    relatedBy: .equal,
                                                    toItem: parentView,
                                                    attribute: .centerX,
                                                    multiplier: 1.0,
                                                    constant: 0.0))
    }
    
    class func configureChildView(_ childView: UIView,
                                  inParentView parentView: UIView,
                                  withInset edgeInsets: UIEdgeInsets) {
        UIView.configureChildView(childView,
                                  inParentView: parentView,
                                  withInset: edgeInsets,
                                  horizontalVisualFormat: "H:|-left-[view]-right-|",
                                  verticalVisualFormat: "V:|-top-[view]-bottom-|")
    }
    
    class func configureChildView(_ childView: UIView,
                                  inParentView parentView: UIView,
                                  withInset edgeInsets: UIEdgeInsets,
                                  horizontalVisualFormat: String,
                                  verticalVisualFormat: String) {
        childView.frame = parentView.bounds
        parentView.addChildView(childView)
        
        let metrics: [String: Any] = ["top": edgeInsets.top,
                                      "bottom": edgeInsets.bottom,
                                      "left": edgeInsets.left,
                                      "right": edgeInsets.right]
        
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: verticalVisualFormat,
                                                                 options: [],
                                                                 metrics: metrics,
                                                                 views: ["view":childView]))
        parentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: horizontalVisualFormat,
                                                                 options: [],
                                                                 metrics: metrics,
                                                                 views: ["view":childView]))
    }
    
    func addChildView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
    }
}

