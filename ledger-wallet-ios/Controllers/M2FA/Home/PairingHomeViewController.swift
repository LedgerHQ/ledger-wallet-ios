//
//  PairingHomeViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingHomeViewController: BaseViewController {
    
    lazy private var pairingTransactionsManager = PairingTransactionsManager()
    private var currentContentViewController: PairingHomeBaseContentViewController! = nil
    private var pairingTransactionDialogViewController: PairingTransactionDialogViewController? = nil
    
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
    
    // MARK: - Interface
    
    override func configureView() {
        super.configureView()
        
        pairingTransactionsManager.delegate = self
    }
    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        currentContentViewController?.view.frame = view.bounds
    }
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if pairingTransactionsManager.tryListening() {
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

extension PairingHomeViewController: PairingTransactionsManagerDelegate {
    
    // MARK: - PairingTransactionsManager delagate

    func pairingTransactionsManager(pairingTransactionsManager: PairingTransactionsManager, didReceiveNewTransactionInfo transactionInfo: PairingTransactionInfo) {
        pairingTransactionDialogViewController = PairingTransactionDialogViewController.instantiateFromNib()
        pairingTransactionDialogViewController?.delegate = self
        pairingTransactionDialogViewController?.transactionInfo = transactionInfo
        presentViewController(pairingTransactionDialogViewController!, animated: true, completion: nil)
    }
    
    func pairingTransactionsManager(pairingTransactionsManager: PairingTransactionsManager, dongleDidCancelCurrentTransactionInfo transactionInfo: PairingTransactionInfo) {
        pairingTransactionDialogViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension PairingHomeViewController: PairingTransactionDialogViewControllerDelegate {
    
    // MARK: - PairingTransactionDialogViewController delegate
    
    func pairingTransactionDialogViewController(pairingTransactionDialogViewController: PairingTransactionDialogViewController, didConfirmTransactionInfo transactionInfo: PairingTransactionInfo) {
        pairingTransactionsManager.confirmTransaction(transactionInfo)
        pairingTransactionDialogViewController.dismissViewControllerAnimated(true, completion: nil)
        self.pairingTransactionDialogViewController = nil
    }
    
    func pairingTransactionDialogViewController(pairingTransactionDialogViewController: PairingTransactionDialogViewController, didRejectTransactionInfo transactionInfo: PairingTransactionInfo) {
        pairingTransactionsManager.rejectTransaction(transactionInfo)
        pairingTransactionDialogViewController.dismissViewControllerAnimated(true, completion: nil)
        self.pairingTransactionDialogViewController = nil
    }
    
}