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
    var fetchRequest: WalletFetchRequest<WalletAllVisibleAccountsFetchRequestProvider>?
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStartRefreshingTransactionsNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStopRefreshingTransactionsNotification, object: nil)
        updateUI()
        
        walletManager?.fetchRequestBuilder.accountsFetchRequestWithIncrementSize(20, order: .Ascending) { fetchRequest in
            self.fetchRequest = fetchRequest
            self.fetchRequest?.allObjects() { objects in
                print(objects)
            }
        }
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
    
}