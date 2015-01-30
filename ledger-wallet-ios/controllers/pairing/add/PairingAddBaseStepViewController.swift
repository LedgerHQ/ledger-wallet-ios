//
//  PairingAddBaseStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddBaseStepViewController: BaseViewController {

    var stepNumber: Int {
        return 0
    }
    var stepIndication: String {
        return ""
    }
    var finalizesFlow: Bool {
        return false
    }
    var data: AnyObject? = nil
    
    final func notifyResult(object: AnyObject) {
        if let parent = parentViewController as? PairingAddViewController {
            parent.handleStepResult(object, stepViewController: self)
        }
    }
    
}
