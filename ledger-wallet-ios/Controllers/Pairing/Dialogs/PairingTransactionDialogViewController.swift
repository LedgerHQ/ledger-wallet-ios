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
    
    @IBOutlet private weak var variableWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var dongleNameLabel: Label!
    @IBOutlet private weak var receipientAddressLabel: Label!
    @IBOutlet private weak var transactionDateLabel: Label!
    @IBOutlet private weak var amountLabel: Label!
    
    weak var delegate: PairingTransactionDialogViewControllerDelegate? = nil
    var transactionInfo: PairingTransactionInfo! = nil {
        didSet {
            if (transactionInfo != nil) { DeviceManager.sharedInstance().vibrate() }
        }
    }
    
    // MARK: - Content size
    
    override func dialogLayoutSize(constraintedSize size: CGSize) -> CGSize {
        variableWidthConstraint?.constant = size.width - dialogContentDistance.left - dialogContentDistance.right
        return super.dialogLayoutSize(constraintedSize: size)
    }
    
    // MARK: - Interface
    
    func updateView() {
        receipientAddressLabel?.text = transactionInfo.recipientAddress
        dongleNameLabel?.text = transactionInfo.dongleName
        amountLabel?.text = Bitcoin.Formatter.stringFromAmount(transactionInfo.outputsAmount)
        transactionDateLabel?.text = NSString(format: localizedString("requested_on_%@"), NSDateFormatter.localizedStringFromDate(transactionInfo.transactionDate, dateStyle: NSDateFormatterStyle.ShortStyle, timeStyle: NSDateFormatterStyle.ShortStyle)) as String
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateView()
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