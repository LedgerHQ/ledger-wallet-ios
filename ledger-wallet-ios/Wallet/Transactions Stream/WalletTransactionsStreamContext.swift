//
//  WalletTransactionsStreamContext.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamContext {
    
    let remoteTransaction: WalletTransactionContainer
    
    var mappedInputs: [WalletTransactionRegularInput: WalletAddress] = [:]
    var mappedOutputs: [WalletTransactionOutput: WalletAddress] = [:]

    var sendOperations: [WalletOperation] = []
    var receiveOperations: [WalletOperation] = []
    var conflictsToAdd: [WalletDoubleSpendConflict] = []
    var transactionsToRemove: [WalletTransaction] = []
    
    init(remoteTransaction: WalletTransactionContainer) {
        self.remoteTransaction = remoteTransaction
    } 

}