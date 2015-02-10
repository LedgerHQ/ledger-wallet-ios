//
//  PairingHomeViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingHomeViewController: BaseViewController {
    
    private var currentContentViewController: PairingHomeBaseContentViewController! = nil
    
    override func configureView() {
        super.configureView()
    
        currentContentViewController = PairingHomeEmptyContentViewController.instantiateFromNib()
        addChildViewController(currentContentViewController)
        currentContentViewController.didMoveToParentViewController(self)
        view.addSubview(currentContentViewController.view)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        currentContentViewController?.view.frame = view.bounds
    }
    
}