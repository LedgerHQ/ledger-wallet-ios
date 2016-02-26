//
//  WalletSpendableTransactionOutput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 26/02/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletSpendableTransactionOutput {
    
    let amount: Int64
    let script: NSData
    let address: WalletAddress?
    
}