//
//  WalletTransactionContainer.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

struct WalletTransactionContainer {
    
    let transaction: WalletTransaction
    let inputs: [WalletTransactionInputType]
    let outputs: [WalletTransactionOutput]
    let block: WalletBlock?
    
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
    
    var regularInputs: [WalletTransactionRegularInput] {
        return inputs.flatMap({ $0 as? WalletTransactionRegularInput })
    }
    
    // MARK: Initialization
    
    init(transaction: WalletTransaction, inputs: [WalletTransactionInputType], outputs: [WalletTransactionOutput], block: WalletBlock?) {
        self.transaction = transaction
        self.inputs = inputs
        self.outputs = outputs
        self.block = block
    }

}

// MARK: - JSONInitializableModel

extension WalletTransactionContainer: JSONInitializableModel {
    
    init?(var JSONObject: [String : AnyObject], parentObject: JSONInitializableModel?) {
        WalletTransactionContainer.normalizeJSON(&JSONObject)
        
        // build block
        let block: WalletBlock?
        if let blockJSON = JSONObject["block"] as? [String: AnyObject] {
            block = WalletBlock(JSONObject: blockJSON, parentObject: nil)
        }
        else {
            block = nil
        }
        
        // build transaction
        guard let
            transaction = WalletTransaction(JSONObject: JSONObject, parentObject: block),
        	inputs = JSONObject["inputs"] as? [[String: AnyObject]],
            outputs = JSONObject["outputs"] as? [[String: AnyObject]]
        else {
            return nil
        }
        
        // inputs and outputs
        let finalOutputs = WalletTransactionOutput.collectionFromJSONArray(outputs, parentObject: transaction)
        var finalInputs: [WalletTransactionInputType] = []
        for input in inputs {
            if let regularInput = WalletTransactionRegularInput(JSONObject: input, parentObject: transaction) {
                finalInputs.append(regularInput)
            }
            else if let coinbaseInput = WalletTransactionCoinbaseInput(JSONObject: input, parentObject: transaction) {
                finalInputs.append(coinbaseInput)
            }
        }
        guard finalOutputs.count > 0 && finalInputs.count > 0 else {
            return nil
        }
    
        self.transaction = transaction
        self.inputs = finalInputs
        self.outputs = finalOutputs
        self.block = block
    }
    
    private static func normalizeJSON(inout JSONObject: [String : AnyObject]) {
        if let
            time = JSONObject["block_time"] as? String,
            hash = JSONObject["block_hash"] as? String,
            height = JSONObject["block_height"] as? Int
        {
            let newJSON = ["hash": hash, "time": time, "height": height]
            JSONObject["block"] = newJSON
        }
        JSONObject.removeValueForKey("block_time")
        JSONObject.removeValueForKey("block_height")
        JSONObject.removeValueForKey("block_hash")
    }
    
}