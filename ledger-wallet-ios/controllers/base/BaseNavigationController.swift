//
//  BaseNavigationController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class BaseNavigationController: UINavigationController {
    
    // MARK: - Status bar management
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if self.topViewController != nil {
            return self.topViewController.preferredStatusBarStyle()
        }
        return super.preferredStatusBarStyle()
    }
    
}

extension BaseNavigationController {
    
    // MARK: - Instantiation
    
    override class func new() -> BaseNavigationController {
        let navigationController = BaseNavigationController(navigationBarClass: NavigationBar.self, toolbarClass: nil)
        (navigationController.navigationBar as! NavigationBar).allure = "navigationBar.nightBlue"
        return navigationController
    }
    
}