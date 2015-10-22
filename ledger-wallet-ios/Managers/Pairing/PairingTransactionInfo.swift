//
//  PairingTransactionInfo.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

struct PairingTransactionInfo: Equatable {
    
    let pinCode: String
    let recipientAddress: String
    let changeAmount: BTCAmount
    let feesAmount: BTCAmount
    let outputsAmount: BTCAmount
    let transactionDate: NSDate
    var dongleName: String? = nil
    
}

func ==(lhs: PairingTransactionInfo, rhs: PairingTransactionInfo) -> Bool {
    return lhs.pinCode == rhs.pinCode && lhs.recipientAddress == rhs.recipientAddress && lhs.changeAmount == rhs.changeAmount &&
    lhs.feesAmount == rhs.feesAmount && lhs.outputsAmount == rhs.outputsAmount && lhs.transactionDate.isEqualToDate(rhs.transactionDate) &&
    lhs.dongleName == rhs.dongleName
}
    