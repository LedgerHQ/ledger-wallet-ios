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
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var listenStartButton: UIButton!
    @IBOutlet private weak var listenStopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStartRefreshingLayoutNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStopRefreshingLayoutNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStartListeningTransactionsNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUI", name: WalletManagerDidStopListeningTransactionsNotification, object: nil)
        updateUI()
    }

    @IBAction func scanForTransactions(sender: AnyObject) {
        walletManager?.startRefreshingLayout()
    }
    
    @IBAction func stopScanForTransactions(sender: AnyObject) {
        walletManager?.stopRefreshingLayout()
    }
    
    @IBAction func listenForTransactions(sender: AnyObject) {
        walletManager?.startListeningTransactions()
    }
    
    @IBAction func stopListenForTransactions(sender: AnyObject) {
        walletManager?.stopListeningTransactions()
    }
    
    private dynamic func updateUI() {
        startButton.enabled = !walletManager!.isRefreshingLayout
        stopButton.enabled = !startButton.enabled
        listenStartButton.enabled = !walletManager!.isListeningTransactions
        listenStopButton.enabled = !listenStartButton.enabled
    }
    
}