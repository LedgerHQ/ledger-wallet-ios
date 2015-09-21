//
//  PairingListViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

final class PairingListViewController: BaseViewController {
    
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
        cell.delegate = self
        return cell
    }
    
}

extension PairingListViewController: PairingListTableViewCellDelegate {
    
    // MARK: - PairingListTableViewCell delegate
    
    func pairingListTableViewCellDidTapDeleteButton(pairingListTableViewCell: PairingListTableViewCell) {
        if let indexPath = tableView.indexPathForCell(pairingListTableViewCell) {
            // ask confirmation
            unowned let weakSelf = self
            let alertController = AlertController(title: localizedString("deleting_this_dongle_pairing"), message: nil)
            alertController.addAction(AlertAction(title: localizedString("cancel"), style: .Cancel, handler: nil))
            alertController.addAction(AlertAction(title: localizedString("delete"), style: .Default, handler: { action in
                // delete model
                let pairingItem = weakSelf.pairingKeychainItems.removeAtIndex(indexPath.row)
                
                // unregister pairing item push token
                RemoteNotificationsManager.sharedInstance().unregisterDeviceTokenFromPairedDongle(pairingItem)
                
                // destroy pairing item
                pairingItem.destroy()
                
                // delete row
                weakSelf.tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                
                // dismiss if empty
                if (weakSelf.pairingKeychainItems.count == 0) {
                    delayOnMainQueue(0.25) {
                        // dismiss
                        weakSelf.complete()
                    }
                }
            }))
            alertController.presentFromViewController(self, animated: true)
        }
    }
    
}

extension PairingListViewController: PairingAddViewControllerDelegate {
    
    // MARK: - PairingAddViewController delegate
    
    func pairingAddViewController(pairingAddViewController: PairingAddViewController, didCompleteWithOutcome outcome: PairingProtocolManager.PairingOutcome, pairingItem: PairingKeychainItem?) {
        // dismiss
        pairingAddViewController.dismissViewControllerAnimated(true) {
            // handle outcome
            if outcome != PairingProtocolManager.PairingOutcome.DeviceTerminated {
                let confirmationDialogViewController = PairingConfirmationDialogViewController.instantiateFromNib()
                confirmationDialogViewController.configureWithPairingOutcome(outcome, pairingItem: pairingItem)
                self.presentViewController(confirmationDialogViewController, animated: true, completion: nil)
            }
        }
    }
    
}