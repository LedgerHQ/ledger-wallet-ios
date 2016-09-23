//
//  CryptoCommon.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class Crypto {

    final class Common {
        
        class func valueGreaterOrEqualThan(value: Int, modulo: Int) -> Int {
            if (value % modulo == 0) { return value }
            return (value + modulo) - ((value + modulo) % modulo)
        }
        
    }
    
}