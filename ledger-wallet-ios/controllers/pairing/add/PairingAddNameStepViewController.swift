//
//  PairingAddNameStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddNameStepViewController: PairingAddBaseStepViewController {
    
    @IBOutlet private weak var centerLayoutConstraint: NSLayoutConstraint!
    
    override var stepIndication: String {
        return localizedString("give_a_name_to_your_wallet")
    }
    override var stepNumber: Int {
        return 3
    }
    override var finalizesFlow: Bool {
        return true
    }
    
    //MARK: Keyboard management
    
    override func keyboardWillHide(userInfo: [NSObject : AnyObject]) {
        centerLayoutConstraint.constant = 0
        view.setNeedsLayout()
        UIView.animateWithDuration(2.0, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    override func keyboardWillShow(userInfo: [NSObject : AnyObject]) {
        centerLayoutConstraint.constant = 100
        view.setNeedsLayout()
        UIView.animateWithDuration(2.0, animations: {
            self.view.layoutIfNeeded()
        })
    }

    
}
