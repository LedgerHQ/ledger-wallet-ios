//
//  PairingHomeViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingHomeViewController: BaseViewController {
    
    lazy private var pairingTransactionsManager = PairingTransactionsManager()
    private var currentContentViewController: PairingHomeBaseContentViewController! = nil
    
    // MARK: - Content
    
    private func switchToContentViewControllerWithClass(viewControllerClass: PairingHomeBaseContentViewController.Type) {
        // destroy current content view controller
        currentContentViewController?.view.removeFromSuperview()
        currentContentViewController?.willMoveToParentViewController(nil)
        currentContentViewController?.removeFromParentViewController()
        
        // create new content view controller
        currentContentViewController = viewControllerClass.instantiateFromNib()
        addChildViewController(currentContentViewController)
        currentContentViewController?.didMoveToParentViewController(self)
        view.addSubview(currentContentViewController.view)
        view.setNeedsLayout()
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        currentContentViewController?.view.frame = view.bounds
    }
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pairingTransactionsManager.startListening() {
            switchToContentViewControllerWithClass(PairingHomeWaitingContentViewController)
        }
        else {
            switchToContentViewControllerWithClass(PairingHomeEmptyContentViewController)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    
        pairingTransactionsManager.stopListening()
    }
    
}