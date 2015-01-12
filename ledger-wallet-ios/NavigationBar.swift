//
//  NavigationBar.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {
    
    //Mark: Content size
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: CGFloat(VisualFactory.Metrics.defaultNavigationBarHeight))
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        return CGSize(width: super.sizeThatFits(size).width, height: CGFloat(VisualFactory.Metrics.defaultNavigationBarHeight))
    }
    
}