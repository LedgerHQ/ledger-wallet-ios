//
//  CryptoData.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 04/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

extension Crypto {
    
    class Data {
        
        class func dataFromString(string: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> NSData {
            return string.dataUsingEncoding(encoding, allowLossyConversion: false)!
        }
        
        class func stringFromData(data: NSData, encoding: NSStringEncoding = NSUTF8StringEncoding) -> String {
            return NSString(data: data, encoding: encoding)!
        }

    }
    
}