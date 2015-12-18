//
//  WalletRemoteTransactionInput.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 14/12/2015.
//  Copyright © 2015 Ledger. All rights reserved.
//

import Foundation

protocol WalletRemoteTransactionInputType { }

// MARK: WalletRemoteTransactionRegularInput

struct WalletRemoteTransactionRegularInput: WalletRemoteTransactionInputType {
    
    let outputHash: String
    let outputIndex: Int
    let value: Int64
    let scriptSignature: String
    let address: String?
    
}

// MARK: WalletRemoteTransactionCoinbaseInput

struct WalletRemoteTransactionCoinbaseInput: WalletRemoteTransactionInputType {
    
    let coinbase: String
    
}

// MARK: JSONInitializableModel

extension WalletRemoteTransactionRegularInput: JSONInitializableModel {
    
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
    }
}

extension WalletRemoteTransactionCoinbaseInput: JSONInitializableModel {
    
    init?(JSONObject: [String : AnyObject]) {
        guard let
            coinbase = JSONObject["coinbase"] as? String
        else {
            return nil
        }
        
        self.coinbase = coinbase
    }
    
}

// MARK: Equatable

extension WalletRemoteTransactionRegularInput: Equatable {}

func ==(lhs: WalletRemoteTransactionRegularInput, rhs: WalletRemoteTransactionRegularInput) -> Bool {
    return lhs.outputHash == rhs.outputHash && lhs.outputIndex == rhs.outputIndex && lhs.value == rhs.value &&
    lhs.scriptSignature == rhs.scriptSignature
}

// MARK: Hashable

extension WalletRemoteTransactionRegularInput: Hashable {
    
    var hashValue: Int { return "\(outputHash) \(outputIndex) \(value) \(scriptSignature)".hashValue }
    
}
