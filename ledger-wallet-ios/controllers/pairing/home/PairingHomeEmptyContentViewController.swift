//
//  PairingHomeEmptyContentViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingHomeEmptyContentViewController: PairingHomeBaseContentViewController {
    
    // MARK: - Actions
    
    @IBAction private func pairNewDeviceButtonTouched() {
        Navigator.Pairing.presentAddViewController(fromViewController: parentHomeViewController, delegate: self)
    }
    
}

extension PairingHomeEmptyContentViewController: PairingAddViewControllerDelegate {
    
    // MARK: - PairingAddViewController delegate
    
    func pairingAddViewController(pairingAddViewController: PairingAddViewController, didCompleteWithOutcome outcome: PairingProtocolManager.PairingOutcome, pairingItem: PairingKeychainItem?) {
        // dismiss
        pairingAddViewController.dismissViewControllerAnimated(true, completion: nil)
        
        // handle outcome
        if outcome != PairingProtocolManager.PairingOutcome.DeviceTerminated {
            let confirmationDialogViewController = PairingConfirmationDialogViewController.instantiateFromNib()
            confirmationDialogViewController.configureWithPairingOutcome(outcome)
            parentHomeViewController.presentViewController(confirmationDialogViewController, animated: true, completion: nil)
        }
    }
    
}