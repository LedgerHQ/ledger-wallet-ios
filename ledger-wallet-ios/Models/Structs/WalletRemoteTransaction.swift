//
//  WalletRemoteTransaction.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletRemoteTransaction {
    
    let transaction: WalletTransaction
    let inputs: [WalletTransactionInputType]
    let outputs: [WalletTransactionOutput]

    var allAddresses: [String] {
        var addresses: [String] = []
        
        for input in inputs {
            if let regularInput = input as? WalletTransactionRegularInput, address = regularInput.address where !addresses.contains(address) {
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
            transaction = WalletTransaction(JSONObject: JSONObject),
        	inputs = JSONObject["inputs"] as? [[String: AnyObject]],
            outputs = JSONObject["outputs"] as? [[String: AnyObject]]
        else {
            return nil
        }
        
        let finalOutputs = WalletTransactionOutput.collectionFromJSONArray(outputs)
        var finalInputs: [WalletTransactionInputType] = []
        for input in inputs {
            if let regularInput = WalletTransactionRegularInput(JSONObject: input) {
                finalInputs.append(regularInput)
            }
            else if let coinbaseInput = WalletTransactionCoinbaseInput(JSONObject: input) {
                finalInputs.append(coinbaseInput)
            }
        }
        
        guard finalOutputs.count > 0 && finalInputs.count > 0 else {
            return nil
        }
    
        self.transaction = transaction
        self.inputs = finalInputs
        self.outputs = finalOutputs
    }
    
}