//
//  WalletTransactionInput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletTransactionInput {
    
    let uid: String?
    let index: UInt32
    let outputHash: String?
    let outputIndex: UInt32?
    let value: Int64?
    let scriptSignature: String?
    let address: String?
    let coinbase: Bool
    let transactionHash: String
    
}

// MARK: - JSONInitializableModel

extension WalletTransactionInput: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject], parentObject: JSONInitializableModel?) {
        guard let
            transaction = parentObject as? WalletTransaction,
        	index = JSONObject["input_index"] as? NSNumber
        else {
            return nil
        }
        
        self.index = index.unsignedIntValue
        self.transactionHash = transaction.hash

        if let _ = JSONObject["coinbase"] as? String {
            self.uid = nil
            self.address = nil
            self.outputIndex = nil
            self.outputHash = nil
            self.value = nil
            self.scriptSignature = nil
            self.coinbase = true
        }
        else {
            guard let
                outputHash = JSONObject["output_hash"] as? String,
                outputIndex = JSONObject["output_index"] as? NSNumber,
                value = JSONObject["value"] as? NSNumber,
                scriptSignature = JSONObject["script_signature"] as? String
            else {
                return nil
            }
            
            self.uid = "\(outputHash)-\(outputIndex)"
            self.address = (JSONObject["addresses"] as? [String])?.first
            self.outputIndex = outputIndex.unsignedIntValue
            self.outputHash = outputHash
            self.value = value.longLongValue
            self.scriptSignature = scriptSignature
            self.coinbase = false
        }
    }
}

// MARK: - Equatable

extension WalletTransactionInput: Equatable {}

func ==(lhs: WalletTransactionInput, rhs: WalletTransactionInput) -> Bool {
    return lhs.outputHash == rhs.outputHash && lhs.outputIndex == rhs.outputIndex && lhs.value == rhs.value &&
        lhs.scriptSignature == rhs.scriptSignature && lhs.address == rhs.address && lhs.transactionHash == rhs.transactionHash &&
        lhs.index == rhs.index && lhs.coinbase == rhs.coinbase && lhs.uid == rhs.uid
}

// MARK: - Hashable

extension WalletTransactionInput: Hashable {
    
    var hashValue: Int { return "\(outputHash) \(outputIndex) \(value) \(scriptSignature) \(address) \(transactionHash) \(index) \(coinbase) \(uid)".hashValue }
    
}

// MARK: - SQLiteFetchableModel

extension WalletTransactionInput: SQLiteFetchableModel {
    
    init?(resultSet: SQLiteStoreResultSet) {
        guard let
            transactionHash = resultSet.stringForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.transactionHashKey)),
            index = resultSet.unsignedInteger32ForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.indexKey)),
            coinbase = resultSet.boolForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.coinbaseKey))
        else {
            return nil
        }
        
        self.uid = resultSet.stringForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.uidKey))
        self.address = resultSet.stringForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.addressKey))
        self.outputIndex = resultSet.unsignedInteger32ForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.outputIndexKey))
        self.outputHash = resultSet.stringForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.outputHashKey))
        self.value = resultSet.integer64ForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.valueKey))
        self.scriptSignature = resultSet.stringForKey(WalletTransactionInputEntity.fieldKeypathWithKey(WalletTransactionInputEntity.scriptSignatureKey))
        self.transactionHash = transactionHash
        self.index = index
        self.coinbase = coinbase
    }
    
}