//
//  NavigationBar.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class NavigationBar: UINavigationBar {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configure()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configure()
    }
    
    override func configure() {
        self.translucent = false
        self.shadowImage = UIImage()
        self.barTintColor = VisualFactory.Colors.nightBlue
        setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 80)
    }
    
}

extension NavigationBar {
    class func uppercaseLabelWithText(title: String) -> UILabel {
        let label = UILabel()
        
        return label
    }
}