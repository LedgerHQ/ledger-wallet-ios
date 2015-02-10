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
        return 3
    }
    
    // MARK: - Interface
    
    override func configureView() {
        super.configureView()

        pinCodeView?.restrictedCharacterSet = NSCharacterSet.hexadecimalCharacterSet()
        pinCodeView?.delegate = self
        pinCodeView?.length = 4
        pinCodeView?.placeholder = "x5Ht"
    
        // remove invisible views
        if (DeviceManager.screenHeightClass() == DeviceManager.HeightClass.Small) {
            indicationLabel?.removeFromSuperview()
        }
        
        pinCodeView?.becomeFirstResponder()
    }
}

extension PairingAddCodeStepViewController: PinCodeViewDelegate {
    
    // MARK: - PinCodeView delegate
    
    func pinCodeViewDidComplete(pinCodeView: PinCodeView, text: String) {
        self.pinCodeView?.resignFirstResponder()
        notifyResult(text)
    }
    
    func pinCodeView(pinCodeView: PinCodeView, didRequestNewIndex index: Int, placeholderChar: String?) {
        if let char = placeholderChar {
            let indication = NSString(format: localizedString("enter_letter_or_value_matching_%@"), char)
            indicationLabel?.text = Optional(indication as! String)
        }
        else {
            indicationLabel?.text = ""
        }
    }
    
}