//
//  PairingHomeBaseContentViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingHomeBaseContentViewController: BaseViewController {
    
    var parentHomeViewController: PairingHomeViewController {
        return self.parentViewController as PairingHomeViewController
    }
    
    @IBAction private func visitHelpCenter() {
        UIApplication.sharedApplication().openURL(NSURL(string: LedgerHelpCenterURL)!)
    }
    
}