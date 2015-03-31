//
//  NavigationItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class NavigationItem: UINavigationItem {
    
    @IBInspectable var titleAllure: String = "navigationBar.title"
    
    // MARK: - Style management
    
    override var title: String? {
        didSet {
            let label = (self.titleView as? Label) ?? Label()
            label.text = title ?? ""
            label.allure = titleAllure
            label.sizeToFit()
            self.titleView = label
        }
    }
    
    // MARK: - Localization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.title = localizedString(self.title ?? "")
    }
    
}
