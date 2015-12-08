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
    
    var walletManager: BaseWalletManager?
    @IBOutlet private weak var startButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didStart", name: WalletManagerDidStartRefreshingLayoutNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didStop", name: WalletManagerDidStopRefreshingLayoutNotification, object: nil)
        updateUI()
    }

    @IBAction func scanForTransactions(sender: AnyObject) {
        walletManager?.startRefreshingLayout()
    }
    
    @IBAction func stopScanForTransactions(sender: AnyObject) {
        walletManager?.stopRefreshingLayout()
    }
    
    private dynamic func didStart() {
        updateUI()
    }
    
    private dynamic func didStop() {
        updateUI()
    }
    
    private func updateUI() {
        startButton.enabled = !walletManager!.isRefreshingLayout
        stopButton.enabled = !startButton.enabled
    }
    
}