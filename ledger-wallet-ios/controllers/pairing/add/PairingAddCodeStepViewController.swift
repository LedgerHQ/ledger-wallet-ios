//
//  PairingAddCodeStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddCodeStepViewController: PairingAddBaseStepViewController {
    
    override var stepIndication: String {
        return localizedString("enter_security_card_value")
    }
    override var stepNumber: Int {
        return 2
    }

    @IBAction func test(sender: AnyObject) {
        completeStep()
    }
    
}