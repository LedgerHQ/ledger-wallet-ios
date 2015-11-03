//
//  PairingConfirmationDialogViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingConfirmationDialogViewController: MessageDialogViewController {
        
    // MARK: - Configuration
    
    func configureWithPairingOutcome(outcome: PairingProtocolManager.PairingOutcome, pairingItem: PairingKeychainItem?) {
        // default to error
        type = .Error
        localizedTitle = localizedString("PAIRING_FAILED")
        
        // configure message
        switch outcome {
        case .DeviceSucceeded:
            type = .Success
            localizedTitle = localizedString("PAIRING_SUCCEEDED")
            localizedMessage = String(format: localizedString("success_pairing_named_%@"), pairingItem?.dongleName ?? "")
        case .ServerDisconnected:
            localizedMessage = localizedString("error_pairing_network")
        case .DongleFailed:
            localizedMessage = localizedString("error_pairing_wrong_validation_code")
        case .DongleTerminated:
            localizedMessage = localizedString("error_pairing_dongle_cancelled")
        case .ServerTimeout:
            localizedMessage = localizedString("error_pairing_timeout")
        default:
            localizedMessage = localizedString("error_pairing_unknown")
        }
        
        // add action
        addAction(MessageDialogAction(type: .Neutral, title: localizedString("CLOSE"), handler: { [weak self] action in
            self?.dismissViewControllerAnimated(true, completion: nil)
        }))
    }
    
    // MARK: - Initialization
    
    override class func interfaceBuilderIdentifier() -> String! {
        return MessageDialogViewController.className()
    }
    
}