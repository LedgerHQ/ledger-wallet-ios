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
        guard let topViewController = topViewController else {
            return super.preferredStatusBarStyle()
        }
        return topViewController.preferredStatusBarStyle()
    }
    
}