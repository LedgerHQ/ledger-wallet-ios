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
    @IBOutlet private weak var tableView: TableView!
    
    private var pairingKeychainItems: [PairingKeychainItem] = []

    // MARK: - Actions
    
    @IBAction func pairNewDeviceButtonTouched() {
        Navigator.Pairing.presentAddViewController(fromViewController: self, delegate: self)
    }
    
    override func complete() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Interface
    
    override func configureView() {
        super.configureView()
        
        actionBar.borderPosition = ActionBarView.BorderPosition.Top
    }

    override func updateView() {
        super.updateView()
        
        tableView?.reloadData()
    }
    
    // MARK: - Model
    
    override func updateModel() {
        pairingKeychainItems = PairingKeychainItem.fetchAll() as! [PairingKeychainItem]
    }
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateModel()
        updateView()
    }
    
}

extension PairingListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - UITableview delegate, data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pairingKeychainItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(PairingListTableViewCell.className(), forIndexPath: indexPath) as! PairingListTableViewCell
        cell.configureWithPairingItem(pairingKeychainItems[indexPath.row])
        return cell
    }
    
}

extension PairingListViewController: PairingAddViewControllerDelegate {
    
    // MARK: - PairingAddViewController delegate
    
    func pairingAddViewController(pairingAddViewController: PairingAddViewController, didCompleteWithOutcome outcome: PairingProtocolManager.PairingOutcome, pairingItem: PairingKeychainItem?) {
        // dismiss
        pairingAddViewController.dismissViewControllerAnimated(true, completion: nil)
        
        // handle outcome
        if outcome != PairingProtocolManager.PairingOutcome.DeviceTerminated {
            let confirmationDialogViewController = PairingConfirmationDialogViewController.instantiateFromNib()
            confirmationDialogViewController.configureWithPairingOutcome(outcome, pairingItem: pairingItem)
            presentViewController(confirmationDialogViewController, animated: true, completion: nil)
        }
    }
    
}