//
//  PairingAddConnectionStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 28/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddConnectionStepViewController: PairingAddBaseStepViewController {

    override var stepIndication: String {
        return localizedString("your_device_is_creating_secure_connection")
    }
    override var stepNumber: Int {
        return 2
    }
    
}