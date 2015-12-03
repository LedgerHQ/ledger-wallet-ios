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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func scanForTransactions(sender: AnyObject) {
        walletManager?.lookForNewTransactions()
    }
    
}