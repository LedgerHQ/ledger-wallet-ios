//
//  ApplicationWalletAccountsViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 19/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

final class ApplicationWalletAccountsViewController: ApplicationViewController {
    
    @IBOutlet private var reloadButton: UIBarButtonItem?
    @IBOutlet private var tableView: UITableView?
    @IBOutlet private var balanceLabel: UILabel?
    @IBOutlet private var accountsLabel: UILabel?
    private var accounts: [WalletAccount] = []
    private var fetchRequest: WalletFetchRequest<WalletVisibleAccountsFetchRequestProvider>?
    private var formatter = BTCNumberFormatter(bitcoinUnit: .BTC, symbolStyle: .Code)
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let
            vc = segue.destinationViewController as? ApplicationWalletAccountDetailViewController,
            cell = sender as? UITableViewCell
        where
            segue.identifier == "ShowAccountDetail" {
            if let indexPath = tableView?.indexPathForCell(cell) {
                let account = accounts[indexPath.row]
                vc.account = account
                vc.context = context
            }
        }
    }
    
    @IBAction private func refreshButtonTouched() {
        context?.transactionsManager.refreshTransactions()
    }
    
    override func handleNewContext(context: ApplicationContext?) {
        accounts = []
        fetchRequest = nil
        handleDidUpdateAccounts()
    }
    
    override func handleDidStartRefreshingTransactions() {
        updateUI()
    }
    
    override func handleDidStopRefreshingTransactions() {
        updateUI()
    }
    
    override func handleDidUpdateAccounts() {
        updateModel()
        updateUI()
    }
    
    override func handleDidMissAccount(request: WalletMissingAccountRequest) {
        let processWithDeviceConnectedBlock = { (deviceAPI: RemoteDeviceAPI) in
            deviceAPI.getExtendedPublicKey(accountIndex: request.accountIndex, completionQueue: NSOperationQueue.mainQueue()) { extendedPublicKey, error in
                guard let extendedPublicKey = extendedPublicKey where error == nil else {
                    request.completeWithAccount(nil)
                    return
                }
                
                let account = WalletAccount(index: request.accountIndex, extendedPublicKey: extendedPublicKey, name: "Recovered account #\(request.accountIndex)")
                request.completeWithAccount(account)
            }
        }
        
        if let deviceAPI = context?.deviceCommunicator.deviceAPI {
            processWithDeviceConnectedBlock(deviceAPI)
        }
        else {
            let remoteViewController = ApplicationRemoteDeviceViewController.instantiateFromMainStoryboard()
            remoteViewController.acceptableIdentifier = context?.identifier
            remoteViewController.deviceCommunicator = context?.deviceCommunicator
            remoteViewController.completionBlock = { success, deviceCommunicator, identifier in
                guard let deviceAPI = deviceCommunicator?.deviceAPI where success else {
                    request.completeWithAccount(nil)
                    return
                }
                
                processWithDeviceConnectedBlock(deviceAPI)
            }
            self.presentViewController(remoteViewController, animated: true, completion: nil)
        }
    }
    
    func updateUI() {
        let refreshing = context?.transactionsManager.isRefreshingTransactions ?? false
        reloadButton?.enabled = !refreshing
        tableView?.reloadData()
        balanceLabel?.text = formatter.stringFromAmount(accounts.reduce(0, combine: { $0 + $1.balance }))
        accountsLabel?.text = "\(accounts.count) account(s)"
    }
    
    func updateModel() {
        context?.transactionsManager.fetchRequestBuilder.accountsFetchRequestWithIncrementSize(20, order: .Ascending) { [weak self] fetchRequest in
            guard let strongSelf = self else { return }

            strongSelf.fetchRequest = fetchRequest
            strongSelf.fetchRequest?.allObjects() { [weak self] objects in
                guard let strongSelf = self else { return }

                if let accounts = objects {
                    strongSelf.accounts = accounts
                    strongSelf.updateUI()
                }
            }
        }
    }
    
}

extension ApplicationWalletAccountsViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}


extension ApplicationWalletAccountsViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath)
        return cell
    }

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let account = accounts[indexPath.row]
        
        cell.textLabel?.text = account.name
        cell.detailTextLabel?.text = formatter.stringFromAmount(account.balance)
    }
    
}