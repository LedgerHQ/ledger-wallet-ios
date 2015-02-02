//
//  CryptoEncode.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 02/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

class CryptoEncode {
    
    class Data {
        
        class func dataFromString(string: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> NSData {
            return string.dataUsingEncoding(encoding, allowLossyConversion: false)!
        }
        
        class func stringFromData(data: NSData, encoding: NSStringEncoding = NSUTF8StringEncoding) -> String {
            return NSString(data: data, encoding: encoding)!
        }
        
    }
    
    class Base16 {
        
        class func dataFromBase16String(string: NSString) -> NSData {
            // check string
            let trimmedString = string.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<> ")).stringByReplacingOccurrencesOfString(" ", withString: "").lowercaseString
            let regex = NSRegularExpression(pattern: "^[0-9a-f]*$", options: .CaseInsensitive, error: nil)
            let found = regex?.firstMatchInString(trimmedString, options: nil, range: NSMakeRange(0, countElements(trimmedString)))
            if (found == nil || found?.range.location == NSNotFound || countElements(trimmedString) % 2 != 0) {
                return NSData()
            }
            
            // build data
            let data = NSMutableData(capacity: countElements(trimmedString) / 2)
            for var index = trimmedString.startIndex; index < trimmedString.endIndex; index = index.successor().successor() {
                let byteString = trimmedString.substringWithRange(Range<String.Index>(start: index, end: index.successor().successor()))
                let num = UInt8(byteString.withCString { strtoul($0, nil, 16) })
                data?.appendBytes([num] as [UInt8], length: 1)
            }
            return data!
        }
        
        class func base16StringFromData(data: NSData) -> String {
            // build string
            let string = NSMutableString(capacity: data.length * 2)
            data.enumerateByteRangesUsingBlock() { bytes, bytesRange, stop in
                for var i = 0; i < bytesRange.length; ++i {
                    string.appendFormat("%02x", UnsafePointer<UInt8>(bytes)[i])
                }
            }
            return string
        }
        
    }
    
}