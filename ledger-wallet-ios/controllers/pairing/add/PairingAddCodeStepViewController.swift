//
//  PairingAddCodeStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddCodeStepViewController: PairingAddBaseStepViewController {
    
    @IBOutlet private weak var pinCodeView: PinCodeView!
    @IBOutlet private weak var indicationLabel: Label!
    
    override var stepIndication: String {
        return localizedString("enter_security_card_value")
    }
    override var stepNumber: Int {
        return 2
    }
    
    //MARK: Interface
    
    override func configureView() {
        super.configureView()
        
        pinCodeView?.becomeFirstResponder()
        pinCodeView?.length = 4
        pinCodeView?.restrictedCharacterSet = NSCharacterSet.hexadecimalCharacterSet()
        pinCodeView?.placeholder = "x5Ht"
    
        // remove invisible views
        if (DeviceManager.screenHeightClass() == DeviceManager.HeightClass.Small) {
            indicationLabel?.removeFromSuperview()
        }
    }
    
}