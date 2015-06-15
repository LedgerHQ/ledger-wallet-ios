//
//  Dictionary+Utils.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 13/01/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Dictionary {
    
    mutating func merge<K, V>(dict: [K: V]) {
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
    
}