//
//  NavigationItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class NavigationItem: UINavigationItem {
    
    override var title: String? {
        didSet {
            let label = (self.titleView as? UILabel) ?? UILabel()
            label.text = title ?? ""
            label.style = "pageTitle"
            label.sizeToFit()
            self.titleView = label
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.title = localizedString(self.title ?? "")
        self.leftBarButtonItem?.customView?.sizeToFit()
        self.rightBarButtonItem?.customView?.sizeToFit()
    }
    
}
