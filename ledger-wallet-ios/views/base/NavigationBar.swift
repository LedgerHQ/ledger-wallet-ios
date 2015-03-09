//
//  NavigationBar.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

@IBDesignable

class NavigationBar: UINavigationBar {
    
    // MARK: - Content size
    
    var barHeight: CGFloat {
        if (UIScreen.mainScreen().bounds.height <= 480) {
            return VisualFactory.Metrics.Views.NavigationBar.smallNavigationBarHeight
        }
        return VisualFactory.Metrics.defaultNavigationBarHeight
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: barHeight)
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return CGSize(width: super.sizeThatFits(size).width, height: barHeight)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // move title and buttons
        for view in self.subviews as [UIView] {
            if (view is UIButton || view is UILabel) {
                if (view === topItem?.leftBarButtonItem?.customView || view === topItem?.rightBarButtonItem?.customView || view === topItem?.titleView) {
                    view.frame = CGRectMake(view.frame.origin.x, round((self.bounds.size.height - view.bounds.size.height) / 2), view.frame.size.width, view.frame.size.height)
                }
            }
        }
    }
    
}