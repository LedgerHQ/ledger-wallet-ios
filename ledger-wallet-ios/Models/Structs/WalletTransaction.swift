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
    
    var isConfirmed: Bool { return blockHash != nil && blockHeight != nil && blockTime != nil }
    
    // MARK: Inititialization
    
    init(hash: String, receiveAt: String, lockTime: Int, fees: Int64, blockHash: String?, blockTime: String?, blockHeight: Int?) {
        self.hash = hash
        self.receiveAt = receiveAt
        self.lockTime = lockTime
        self.fees = fees
        self.blockHash = blockHash
        self.blockTime = blockTime
        self.blockHeight = blockHeight
    }
    
}

// MARK: - JSONInitializableModel

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
        self.blockTime = resultSet.stringForKey(WalletTransactionEntity.blockTimeKey)
        self.blockHeight = resultSet.integerForKey(WalletTransactionEntity.blockHeightKey)
    }
    
}