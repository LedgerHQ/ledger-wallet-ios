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
    let outputIndex: Int
    
}

// MARK: JSONInitializableModel

extension WalletRemoteTransactionOutput: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            addresses = JSONObject["addresses"] as? [String],
            value = JSONObject["value"] as? NSNumber,
            scriptHex = JSONObject["script_hex"] as? String,
            outputIndex = JSONObject["output_index"] as? Int
        else {
            return nil
        }
        
        self.address = addresses.first
        self.scriptHex = scriptHex
        self.outputIndex = outputIndex
        self.value = value.longLongValue
    }
    
}