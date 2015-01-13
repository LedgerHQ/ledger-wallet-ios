//
//  ViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    //MARK: Status bar style
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    //MARK: Navigation item management
    
    func navigationItemLocalizedText() -> String {
        if let title = self.navigationItem.title {
            return title
        }
        if let title = self.title {
            return title
        }
        return ""
    }
    
    func updateNavigationItemTitle() {
        let label = UILabel(localizableValue: navigationItemLocalizedText(), style: "pageTitle")
        label.sizeToFit()
        self.navigationItem.titleView = label
    }
    
    //MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateNavigationItemTitle()
    }

}

