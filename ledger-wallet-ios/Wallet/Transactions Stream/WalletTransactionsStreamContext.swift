//
//  WalletTransactionsStreamContext.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 16/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

final class WalletTransactionsStreamContext {
    
    let transaction: WalletRemoteTransaction
    var sendOperations: [WalletOperation] = []
    var receiveOperations: [WalletOperation] = []
    var mappedInputs: [WalletRemoteTransactionRegularInput: WalletAddress] = [:]
    var mappedOutputs: [WalletRemoteTransactionOutput: WalletAddress] = [:]
    
    init(transaction: WalletRemoteTransaction) {
        self.transaction = transaction
    } 

}