//
//  NavigationController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    // MARK: Status bar management
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if self.topViewController != nil {
            return self.topViewController.preferredStatusBarStyle()
        }
        return super.preferredStatusBarStyle()
    }
    
}