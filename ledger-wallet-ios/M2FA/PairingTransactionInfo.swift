//
//  PairingTransactionInfo.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

struct PairingTransactionInfo {
    
    let pinCode: String
    let recipientAddress: String
    let amount: BTCAmount
    let transactionDate: NSDate
    var dongleName: String? = nil
    
    init(pinCode: String, recipientAddress: String, amount: BTCAmount) {
        self.pinCode = pinCode
        self.recipientAddress = recipientAddress
        self.amount = amount
        self.transactionDate = NSDate()
    }
    
}

// MARK: - Equatable

extension PairingTransactionInfo: Equatable {}

func ==(lhs: PairingTransactionInfo, rhs: PairingTransactionInfo) -> Bool {
    return lhs.pinCode == rhs.pinCode && lhs.recipientAddress == rhs.recipientAddress &&
        lhs.amount == rhs.amount && lhs.transactionDate.isEqualToDate(rhs.transactionDate) &&
        lhs.dongleName == rhs.dongleName
}
    