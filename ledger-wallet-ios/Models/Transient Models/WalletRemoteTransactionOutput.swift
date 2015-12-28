//
//  WalletRemoteTransactionOutput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletRemoteTransactionOutput {

    let value: Int64
    let scriptHex: String
    let address: String?
    let index: Int
    
}

// MARK: JSONInitializableModel

extension WalletRemoteTransactionOutput: JSONInitializableModel {
    
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
    }
    
}

// MARK: Equatable

extension WalletRemoteTransactionOutput: Equatable {}

func ==(lhs: WalletRemoteTransactionOutput, rhs: WalletRemoteTransactionOutput) -> Bool {
    return lhs.value == rhs.value && lhs.scriptHex == rhs.scriptHex && lhs.index == rhs.index
}

// MARK: Hashable

extension WalletRemoteTransactionOutput: Hashable {
    
    var hashValue: Int { return "\(index) \(scriptHex) \(value)".hashValue }
    
}