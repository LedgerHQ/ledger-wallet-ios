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
        
        class func dataFromString(string: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> NSData! {
            return string.dataUsingEncoding(encoding, allowLossyConversion: false)!
        }
        
        class func stringFromData(data: NSData, encoding: NSStringEncoding = NSUTF8StringEncoding) -> String! {
            return NSString(data: data, encoding: encoding)! as! String
        }
        
        class func splitDataInTwo(data: NSData) -> (NSData, NSData)  {
            if (data.length == 0 || data.length % 2 != 0) {
                return (NSData(), NSData())
            }
            
            let partLength = data.length / 2
            return (data.subdataWithRange(NSMakeRange(0, partLength)), data.subdataWithRange(NSMakeRange(partLength, partLength)))
        }

    }
    
}