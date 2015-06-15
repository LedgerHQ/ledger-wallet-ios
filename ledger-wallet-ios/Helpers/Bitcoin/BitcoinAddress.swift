//
//  BitcoinAddress.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 09/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Bitcoin {
    
    class Address {
        
        class func verifyPublicAddress(address: String) -> Bool {
            return BTCAddress(string: address) != nil
        }
        
    }
    
}