//
//  WalletRemoteTransaction.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletRemoteTransaction {
    
    let hash: String
    let receiveAt: String
    let inputs: [WalletRemoteTransactionInputType]
    let outputs: [WalletRemoteTransactionOutput]
    let lockTime: Int
    let confirmations: Int
    let fees: Int64
    let blockHash: String?
    let blockTime: String?
    let blockHeight: Int?
    
    var allAddresses: [String] {
        var addresses: [String] = []
        
        for input in inputs {
            if let regularInput = input as? WalletRemoteTransactionRegularInput, address = regularInput.address where !addresses.contains(address) {
                addresses.append(address)
            }
        }
        for output in outputs {
            if let address = output.address where !addresses.contains(address) {
                addresses.append(address)
            }
        }
        return addresses
    }

}

// MARK: JSONInitializableModel

extension WalletRemoteTransaction: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            hash = JSONObject["hash"] as? String,
            receiveAt = JSONObject["chain_received_at"] as? String,
            lockTime = JSONObject["lock_time"] as? Int,
            confirmations = JSONObject["confirmations"] as? Int,
            fees = JSONObject["fees"] as? NSNumber,
        	inputs = JSONObject["inputs"] as? [[String: AnyObject]],
            outputs = JSONObject["outputs"] as? [[String: AnyObject]]
        else {
            return nil
        }
        
        let finalOutputs = WalletRemoteTransactionOutput.collectionFromJSONArray(outputs)
        var finalInputs: [WalletRemoteTransactionInputType] = []
        for input in inputs {
            if let regularInput = WalletRemoteTransactionRegularInput(JSONObject: input) {
                finalInputs.append(regularInput)
            }
            else if let coinbaseInput = WalletRemoteTransactionCoinbaseInput(JSONObject: input) {
                finalInputs.append(coinbaseInput)
            }
        }
        
        guard finalOutputs.count > 0 && finalInputs.count > 0 else {
            return nil
        }
    
        self.hash = hash
        self.receiveAt = receiveAt
        self.lockTime = lockTime
        self.confirmations = confirmations
        self.fees = fees.longLongValue
        self.blockHash = JSONObject["block_hash"] as? String
        self.blockTime = JSONObject["block_time"] as? String
        self.blockHeight = JSONObject["block_height"] as? Int
        self.inputs = finalInputs
        self.outputs = finalOutputs
    }
    
}