//
//  PairingListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingListViewController: BaseViewController {
    
    @IBOutlet private weak var actionBar: ActionBarView!
    @IBOutlet private weak var pairingStatusLabel: Label!
    
    lazy private var pairingTransactionsManager: PairingTransactionsManager = PairingTransactionsManager()
    
    // MARK: Actions
    
    @IBAction private func pairNewDongleButtonTouched(sender: AnyObject) {
        let navigationController = NavigationController.instantiateFromStoryboard(storyboard)
        let addDongleViewController = PairingAddViewController.instantiateFromStoryboard(storyboard)
        addDongleViewController.delegate = self
        navigationController.viewControllers = [addDongleViewController]
        presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: Interface
    
    override func configureView() {
        super.configureView()
        
        actionBar.borderPosition = ActionBarView.BorderPosition.Top
        pairingStatusLabel.text = localizedString("WAITING_FOR_AN_OPERATION")
    }
    
    override func updateView() {
        super.updateView()
        
//        delayOnMainQueue(0.5) {
//            let vc = PairingTransactionDialogViewController.instantiateFromNib()
//            self.presentViewController(vc, animated: true, completion: nil)
//        }
    }
    
    // MARK: View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        pairingTransactionsManager.startListening()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    
        pairingTransactionsManager.stopListening()
    }
    
}

extension PairingListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: UITableview delegate, data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PairingListTableViewCell.className(), forIndexPath: indexPath) as PairingListTableViewCell
        return cell
    }
    
}

extension PairingListViewController: PairingAddViewControllerDelegate {
    
    // MARK: PairingAddViewController delegate
    
    func pairingAddViewController(pairingAddViewController: PairingAddViewController, didCompleteWithOutcome outcome: PairingProtocolManager.PairingOutcome) {
        // dismiss
        pairingAddViewController.dismissViewControllerAnimated(true, completion: nil)
        
        // handle outcome
        if outcome != PairingProtocolManager.PairingOutcome.DeviceTerminated {
            let confirmationDialogViewController = PairingConfirmationDialogViewController.instantiateFromNib()
            confirmationDialogViewController.configureWithPairingOutcome(outcome)
            presentViewController(confirmationDialogViewController, animated: true, completion: nil)
        }
    }
    
}