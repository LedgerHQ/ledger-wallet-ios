//
//  NavigationItem.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class NavigationItem: UINavigationItem {
    
    // MARK: - Style management
    
    @IBInspectable var titleAllure: String? {
        get {
            return (self.titleView as? Label)?.allure
        }
        set {
            let label = self.titleView as? Label ?? Label()
            label.allure = newValue
            if self.titleView == nil {
                self.titleView = label
            }
        }
    }
    
    override var title: String? {
        didSet {
            let label = self.titleView as? Label ?? Label()
            label.text = title
            label.sizeToFit()
            if self.titleView == nil {
                self.titleView = label
            }
        }
    }
    
    // MARK: - Localization
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.title = localizedString(self.title ?? "")
    }
    
}
