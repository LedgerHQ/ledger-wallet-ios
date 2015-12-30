//
//  WalletTransaction.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletTransaction {
    
    let hash: String
    let receiveAt: String
    let lockTime: Int
    let fees: Int64
    let blockHash: String?
    let blockTime: String?
    let blockHeight: Int?
    
}

// MARK: JSONInitializableModel

extension WalletTransaction: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            hash = JSONObject["hash"] as? String,
            receiveAt = JSONObject["chain_received_at"] as? String,
            lockTime = JSONObject["lock_time"] as? Int,
            fees = JSONObject["fees"] as? NSNumber
        else {
            return nil
        }
        
        self.hash = hash
        self.receiveAt = receiveAt
        self.lockTime = lockTime
        self.fees = fees.longLongValue
        self.blockHash = JSONObject["block_hash"] as? String
        self.blockTime = JSONObject["block_time"] as? String
        self.blockHeight = JSONObject["block_height"] as? Int
    }
    
}