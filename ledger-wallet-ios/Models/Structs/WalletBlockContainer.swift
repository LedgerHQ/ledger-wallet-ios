//
//  WalletBlockContainer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 12/01/2016.
//  Copyright © 2016 Ledger. All rights reserved.
//

import Foundation

struct WalletBlockContainer {
    
    let block: WalletBlock
    let transactionHashes: [String]
    
}

// MARK: - JSONInitializableModel

extension WalletBlockContainer: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject], parentObject: JSONInitializableModel?) {
        guard let
            transactionHashes = JSONObject["transaction_hashes"] as? [String],
            block = WalletBlock(JSONObject: JSONObject, parentObject: nil)
        where
            transactionHashes.count > 0
        else {
            return nil
        }
        
        self.block = block
        self.transactionHashes = transactionHashes
    }
    
}