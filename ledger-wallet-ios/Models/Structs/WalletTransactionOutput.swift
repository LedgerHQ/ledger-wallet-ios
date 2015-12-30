//
//  WalletTransactionOutput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletTransactionOutput {
    
    let value: Int64
    let scriptHex: String
    let address: String?
    let index: Int
    let transactionHash: String?
    
}

// MARK: JSONInitializableModel

extension WalletTransactionOutput: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            addresses = JSONObject["addresses"] as? [String],
            value = JSONObject["value"] as? NSNumber,
            scriptHex = JSONObject["script_hex"] as? String,
            index = JSONObject["output_index"] as? Int
        else {
            return nil
        }
        
        self.address = addresses.first
        self.scriptHex = scriptHex
        self.index = index
        self.value = value.longLongValue
        self.transactionHash = nil
    }
    
}

// MARK: Equatable

extension WalletTransactionOutput: Equatable {}

func ==(lhs: WalletTransactionOutput, rhs: WalletTransactionOutput) -> Bool {
    return lhs.value == rhs.value && lhs.scriptHex == rhs.scriptHex && lhs.index == rhs.index && lhs.transactionHash == rhs.transactionHash && lhs.address == rhs.address
}

// MARK: Hashable

extension WalletTransactionOutput: Hashable {
    
    var hashValue: Int { return "\(index) \(scriptHex) \(value) \(transactionHash) \(address)".hashValue }
    
}