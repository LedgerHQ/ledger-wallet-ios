//
//  WalletTestViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/11/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation
import UIKit

class WalletTestViewController: BaseViewController {
    
    var walletManager: WalletManagerType?
    private var fetchRequest: WalletFetchRequest<WalletVisibleAccountsFetchRequestProvider>?
    private var accounts: [WalletAccount] = []
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStartRefreshingTransactionsNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStopRefreshingTransactionsNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateModel", name: WalletManagerDidUpdateAccountsNotification, object: nil)
        updateUI()
        updateModel()
    }

    @IBAction func scanForTransactions(sender: AnyObject) {
        walletManager?.startRefreshingTransactions()
    }
    
    @IBAction func stopScanForTransactions(sender: AnyObject) {
        walletManager?.stopRefreshingTransactions()
    }
    
    @IBAction func dropWallet(sender: AnyObject) {
        walletManager?.stopAllServices()
        walletManager = nil
    }

    private dynamic func updateUI() {
        startButton.enabled = !walletManager!.isRefreshingTransactions
        stopButton.enabled = !startButton.enabled
    }
    
    private dynamic func updateModel() {
        walletManager?.fetchRequestBuilder.accountsFetchRequestWithIncrementSize(20, order: .Ascending) { fetchRequest in
            self.fetchRequest = fetchRequest
            self.fetchRequest?.allObjects() { objects in
                self.accounts = objects!
                self.tableView.reloadData()
            }
        }
    }
    
}

extension WalletTestViewController: UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("AccountCell", forIndexPath: indexPath)
        return cell
    }
    
}

extension WalletTestViewController: UITableViewDelegate {

    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let account = accounts[indexPath.row]
        cell.textLabel?.text = "Account #\(account.index)"
        cell.detailTextLabel?.text = String(account.balance)
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let account = accounts[indexPath.row]
        let vc = WalletOperationsViewController.instantiateFromMainStoryboard()
        vc.account = account
        vc.walletManager = walletManager
        navigationController?.pushViewController(vc, animated: true)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}