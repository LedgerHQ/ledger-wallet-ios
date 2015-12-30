//
//  WalletTransactionInput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 30/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletTransactionInputType { }

struct WalletTransactionRegularInput: WalletTransactionInputType {
    
    let outputHash: String
    let outputIndex: Int
    let value: Int64
    let scriptSignature: String
    let address: String?
    let transactionHash: String?
    
}

struct WalletTransactionCoinbaseInput: WalletTransactionInputType {
    
    let coinbase: String
    let transactionHash: String?
    
}

// MARK: JSONInitializableModel

extension WalletTransactionRegularInput: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            outputHash = JSONObject["output_hash"] as? String,
            outputIndex = JSONObject["output_index"] as? Int,
            value = JSONObject["value"] as? NSNumber,
            scriptSignature = JSONObject["script_signature"] as? String,
            addresses = JSONObject["addresses"] as? [String]
        else {
            return nil
        }
        
        self.address = addresses.first
        self.outputIndex = outputIndex
        self.outputHash = outputHash
        self.value = value.longLongValue
        self.scriptSignature = scriptSignature
        self.transactionHash = nil
    }
}

extension WalletTransactionCoinbaseInput: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            coinbase = JSONObject["coinbase"] as? String
        else {
            return nil
        }
        
        self.coinbase = coinbase
        self.transactionHash = nil
    }
    
}

// MARK: Equatable

extension WalletTransactionRegularInput: Equatable {}

func ==(lhs: WalletTransactionRegularInput, rhs: WalletTransactionRegularInput) -> Bool {
    return lhs.outputHash == rhs.outputHash && lhs.outputIndex == rhs.outputIndex && lhs.value == rhs.value &&
        lhs.scriptSignature == rhs.scriptSignature && lhs.address == rhs.address && lhs.transactionHash == rhs.transactionHash
}

// MARK: Hashable

extension WalletTransactionRegularInput: Hashable {
    
    var hashValue: Int { return "\(outputHash) \(outputIndex) \(value) \(scriptSignature) \(address) \(transactionHash)".hashValue }
    
}
