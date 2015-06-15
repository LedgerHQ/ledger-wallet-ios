//
//  PairingAddFinalizeStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 29/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingAddFinalizeStepViewController: PairingAddBaseStepViewController {
    
    override var stepIndication: String {
        return localizedString("ledger_wallet_is_finalizing_pairing")
    }
    override var stepNumber: Int {
        return 4
    }
    
}