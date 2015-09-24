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
    
    // MARK: - Interface
    
    override func configureView() {
        super.configureView()
        
        actionBar.borderPosition = ActionBarView.BorderPosition.Top
    }
    
    // MARK: - Model
    
    func updateModel() {
        pairingKeychainItems = PairingKeychainItem.fetchAll() as! [PairingKeychainItem]
    }
    
    // MARK: - View lifecycle
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        updateModel()
        tableView.reloadData()
    }
    
}

extension PairingListViewController: CompletionResultable {
    
    @IBAction func complete() {
        dismissViewControllerAnimated(true, completion: nil)
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
            let alertController = AlertController(title: localizedString("deleting_this_dongle_pairing"), message: nil)
            alertController.addAction(AlertAction(title: localizedString("cancel"), style: .Cancel, handler: nil))
            alertController.addAction(AlertAction(title: localizedString("delete"), style: .Destructive, handler: { action in
                // get model
                let pairingItem = self.pairingKeychainItems[indexPath.row]
                let pairingId = pairingItem.pairingId
                
                // destroy pairing item
                if pairingItem.destroy() {
                    // unregister pairing item push token
                    if pairingId != nil {
                        RemoteNotificationsManager.sharedInstance().unregisterDeviceTokenFromPairedDongleWithId(pairingId!)
                    }
                    
                    // delete model
                    self.pairingKeychainItems.removeAtIndex(indexPath.row)
                    
                    // delete row
                    self.tableView?.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)
                    
                    // dismiss if empty
                    if self.pairingKeychainItems.isEmpty {
                        delayOnMainQueue(0.25) {
                            // dismiss
                            self.complete()
                        }
                    }
                }
                else {
                    // warn user
                    let alertController = AlertController(title: localizedString("error_pairing_unknown"), message: nil)
                    alertController.addAction(AlertAction(title: localizedString("OK"), style: .Default, handler: nil))
                    alertController.presentFromViewController(self, animated: true)
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