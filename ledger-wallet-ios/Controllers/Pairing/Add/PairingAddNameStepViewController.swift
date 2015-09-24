//
//  PairingAddNameStepViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

final class PairingAddNameStepViewController: PairingAddBaseStepViewController {
    
    @IBOutlet private weak var nameTextField: TextField!
    @IBOutlet private weak var walletImageView: UIImageView!
    @IBOutlet private weak var indicationLabel: Label!
    
    override var stepIndication: String {
        return localizedString("your_device_is_now_paired")
    }
    override var stepNumber: Int {
        return 5
    }
    override var finalizable: Bool {
        return true
    }
    override var cancellable: Bool {
        return false
    }
    
    // MARK: - Interface
    
    private func checkThatNameIsUnique(name: String?) -> Bool {
        guard let name = name else { return false }
        
        var message:String? = nil
        
        // create message
        if name.isEmpty {
            message = localizedString("you_need_to_provide_a_dongle_name")
        }
        else if (!PairingProtocolContext.canCreatePairingKeychainItemNamed(name)) {
            message = localizedString("a_dongle_with_this_name_already_exists")
        }
        else {
            message = nil
        }
        
        // show message if necessary
        if message != nil {
            let alertController = AlertController(alert: message!)
            alertController.presentFromViewController(self, animated: true)
            return false
        }
        return true
    }
    
    override func configureView() {
        super.configureView()
        
        nameTextField?.delegate = self
        
        // remove invisible views
        if (DeviceManager.sharedInstance().screenHeightClass == DeviceManager.HeightClass.Medium) {
            indicationLabel?.removeFromSuperview()
        }
        if (DeviceManager.sharedInstance().screenHeightClass == DeviceManager.HeightClass.Small) {
            indicationLabel?.removeFromSuperview()
            walletImageView?.removeFromSuperview()
        }
        
        nameTextField?.becomeFirstResponder()
    }
    
}

extension PairingAddNameStepViewController: CompletionResultable {
    
    func complete() {
        // verify entered name
        if checkThatNameIsUnique(nameTextField.text) {
            notifyResult(nameTextField.text!)
        }
    }
    
}

extension PairingAddNameStepViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        complete()
        return false
    }
    
}
