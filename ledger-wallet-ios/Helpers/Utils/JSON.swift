//
//  JSON.swift
//  ledger-wallet-ios
//
//  Created by Nicolas Bigot on 10/02/2015.
//  Copyright (c) 2015 Ledger. All rights reserved.
//

import Foundation

final class JSON {
    
    class func JSONObjectFromData(data: NSData) -> AnyObject? {
        return try? NSJSONSerialization.JSONObjectWithData(data, options: [])
    }
    
    class func dataFromJSONObject(object: AnyObject) -> NSData? {
        return try? NSJSONSerialization.dataWithJSONObject(object, options: [])
    }
    
}