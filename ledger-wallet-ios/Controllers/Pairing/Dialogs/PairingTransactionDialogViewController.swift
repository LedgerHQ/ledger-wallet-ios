//
//  PairingTransactionDialogViewController.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 25/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import UIKit

protocol PairingTransactionDialogViewControllerDelegate: class {
    
    func pairingTransactionDialogViewController(pairingTransactionDialogViewController: PairingTransactionDialogViewController, didConfirmTransactionInfo transactionInfo: PairingTransactionInfo)
    func pairingTransactionDialogViewController(pairingTransactionDialogViewController: PairingTransactionDialogViewController, didRejectTransactionInfo transactionInfo: PairingTransactionInfo)
    
}

final class PairingTransactionDialogViewController: DialogViewController {
    
    @IBOutlet private weak var dongleNameLabel: Label!
    @IBOutlet private weak var receipientAddressLabel: Label!
    @IBOutlet private weak var transactionDateLabel: Label!
    @IBOutlet private weak var amountLabel: Label!
    
    weak var delegate: PairingTransactionDialogViewControllerDelegate? = nil
    var transactionInfo: PairingTransactionInfo! = nil {
        didSet {
            if (transactionInfo != nil) { DeviceManager.sharedInstance.vibrate() }
        }
    }
    
    // MARK: - Interface
    
    override func configureView() {
        super.configureView()
        
        let formatter = BTCNumberFormatter(bitcoinUnit: BTCNumberFormatterUnit.BTC, symbolStyle: BTCNumberFormatterSymbolStyle.Code)
        formatter.minimumFractionDigits = 3
        formatter.decimalSeparator = "."
        
        receipientAddressLabel?.text = transactionInfo.recipientAddress
        dongleNameLabel?.text = transactionInfo.dongleName
        amountLabel?.text = formatter.stringFromAmount(transactionInfo.amount)
        transactionDateLabel?.text = NSString(format: localizedString("requested_on_%@"), NSDateFormatter.localizedStringFromDate(transactionInfo.transactionDate, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)) as String
    }

}

extension PairingTransactionDialogViewController: CompletionResultable {
    
    @IBAction func complete() {
        self.delegate?.pairingTransactionDialogViewController(self, didConfirmTransactionInfo: transactionInfo)
    }
    
    @IBAction func cancel() {
        self.delegate?.pairingTransactionDialogViewController(self, didRejectTransactionInfo: transactionInfo)
    }
    
}