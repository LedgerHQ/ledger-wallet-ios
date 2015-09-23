//
//  PairingConfirmationDialogViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 22/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class PairingConfirmationDialogViewController: DialogViewController {
    
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
    
    func configureWithPairingOutcome(outcome: PairingProtocolManager.PairingOutcome, pairingItem: PairingKeychainItem?) {
        // default to error
        messageType = MessageType.Error
        localizedTitle = localizedString("PAIRING_FAILED")
        
        // configure message
        switch outcome {
        case .DeviceSucceeded:
            messageType = MessageType.Success
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
    }
    
    // MARK: - Interface 
    
    func updateView() {
        iconImageView?.image = messageType == MessageType.Success ? UIImage(named: "icon_valid_green") : UIImage(named: "icon_error_red")
        titleLabel?.text = localizedTitle
        messageLabel?.text = localizedMessage
    }
    
    // MARK: - Content size
    
    override func dialogLayoutSize(constraintedSize size: CGSize) -> CGSize {
        variableWidthConstraint?.constant = size.width - dialogContentDistance.left - dialogContentDistance.right
        return super.dialogLayoutSize(constraintedSize: size)
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateView()
    }
    
}

extension PairingConfirmationDialogViewController: CompletionResultable {
    
    @IBAction func complete() {
        dismissViewControllerAnimated(true, completion: nil)
    }

}