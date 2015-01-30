//
//  PairingAddNameStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

class PairingAddNameStepViewController: PairingAddBaseStepViewController {
    
    @IBOutlet private weak var nameTextField: TextField!
    @IBOutlet private weak var walletImageView: UIImageView!
    @IBOutlet private weak var indicationLabel: Label!
    
    override var stepIndication: String {
        return localizedString("your_device_is_now_paired")
    }
    override var stepNumber: Int {
        return 5
    }
    override var finalizesFlow: Bool {
        return true
    }
    
    // MARK: Actions
    
    override func complete() {
        super.complete()
        
        notifyResult("this is a name")
    }
    
    // MARK: Interface
    
    override func configureView() {
        super.configureView()
        
        nameTextField?.delegate = self
        
        // remove invisible views
        if (DeviceManager.screenHeightClass() == DeviceManager.HeightClass.Medium) {
            indicationLabel?.removeFromSuperview()
        }
        if (DeviceManager.screenHeightClass() == DeviceManager.HeightClass.Small) {
            indicationLabel?.removeFromSuperview()
            walletImageView?.removeFromSuperview()
        }
        
        nameTextField?.becomeFirstResponder()
    }
    
}

extension PairingAddNameStepViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        complete()
        return false
    }
    
}
