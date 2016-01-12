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
    
    var isConfirmed: Bool { return blockHash != nil }
    
}

// MARK: - JSONInitializableModel

extension WalletTransaction: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject], parentObject: JSONInitializableModel?) {
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
        self.blockHash = (parentObject as? WalletBlock)?.hash
    }
    
}

// MARK: - SQLiteFetchableModel

extension WalletTransaction: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            hash = resultSet.stringForKey(WalletTransactionEntity.hashKey),
            receiveAt = resultSet.stringForKey(WalletTransactionEntity.receptionDateKey),
            lockTime = resultSet.integerForKey(WalletTransactionEntity.lockTimeKey),
            fees = resultSet.integer64ForKey(WalletTransactionEntity.feesKey)
        else {
            return nil
        }
        
        self.hash = hash
        self.receiveAt = receiveAt
        self.lockTime = lockTime
        self.fees = fees
        self.blockHash = resultSet.stringForKey(WalletTransactionEntity.blockHashKey)
    }
    
}