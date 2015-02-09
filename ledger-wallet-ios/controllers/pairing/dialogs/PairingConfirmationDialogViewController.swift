//
//  PairingConfirmationDialogViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class PairingConfirmationDialogViewController: DialogViewController {
    
    enum MessageType {
        case Error
        case Success
    }
    
    var messageType: MessageType = MessageType.Success
    var localizedTitle = ""
    var localizedMessage = ""
    
    @IBOutlet private weak var variableWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: Label!
    @IBOutlet private weak var messageLabel: Label!
    
    // MARK: - Configuration
    
    func configureWithPairingOutcome(outcome: PairingProtocolManager.PairingOutcome) {
        // default to error
        messageType = MessageType.Error
        localizedTitle = localizedString("PAIRING_FAILED")
        
        // configure message
        switch outcome {
        case .DeviceSucceeded:
            messageType = MessageType.Success
            localizedTitle = localizedString("PAIRING_SUCCEEDED")
            localizedMessage = localizedString("success_pairing_named_%@") // TODO:
        case .ServerDisconnected:
            localizedMessage = localizedString("error_pairing_network")
        case .DongleFailed:
            localizedMessage = localizedString("error_pairing_wrong_validation_code")
        case .DongleTerminated:
            localizedMessage = localizedString("error_pairing_dongle_cancelled")
        default:
            localizedMessage = localizedString("error_pairing_unknown")
        }
    }
    
    // MARK: - Interface 
    
    override func updateView() {
        super.updateView()
        
        iconImageView?.image = messageType == MessageType.Success ? UIImage(named: "icon_valid_green") : UIImage(named: "icon_error_red")
        titleLabel?.text = localizedTitle
        messageLabel?.text = localizedMessage
    }
    
    // MARK: - Actions
    
    override func complete() {
        super.complete()
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Content size
    
    override func dialogLayoutSize(constraintedSize size: CGSize) -> CGSize {
        variableWidthConstraint?.constant = size.width - dialogContentDistance.left - dialogContentDistance.right
        return super.dialogLayoutSize(constraintedSize: size)
    }
    
}