//
//  BaseViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 07/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    // MARK: Status bar style
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // MARK: Interface
    
    func configureView() {

    }

    // MARK: Layout 
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // resize navigation items
        self.navigationItem.leftBarButtonItem?.customView?.sizeToFit()
        self.navigationItem.rightBarButtonItem?.customView?.sizeToFit()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configure main view
        configureView()
    }
    
}