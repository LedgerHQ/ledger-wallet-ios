//
//  CryptoBase16.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Crypto {
    
    final class Encode {
        
        // MARK: - Base 16
        
        class func dataFromBase16String(string: String) -> NSData? {
            return BTCDataFromHex(string)
        }
        
        class func base16StringFromData(data: NSData) -> String? {
            return BTCHexFromData(data)
        }
        
        // MARK: - Base 58

        class func dataFromBase58CheckString(string: String) -> NSData? {
            return BTCDataFromBase58Check(string)
        }
        
        class func base58CheckStringFromData(data: NSData) -> String? {
            return BTCBase58CheckStringWithData(data)
        }
        
        class func dataFromBase58String(string: String) -> NSData? {
            return BTCDataFromBase58(string)
        }
        
        class func base58StringFromData(data: NSData) -> String? {
            return BTCBase58StringWithData(data)
        }
        
    }
    
}